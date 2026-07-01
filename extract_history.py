"""
extract_history.py
------------------
Extrator forense de historico de navegacao a partir de imagens E01.

Uso:
    uv run python extract_history.py
    (o script perguntara as informacoes necessarias)

Dependencias:
    dissect (pure-python, instalado via uv)
"""

import sqlite3
import tempfile
import os
import sys
import re
import subprocess
from datetime import datetime, timezone, timedelta
from urllib.parse import urlparse
from pathlib import Path

# ---------------------------------------------------------------------------
# UTF-8 no terminal (para emojis e acentos no console)
# ---------------------------------------------------------------------------
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

from dissect.target import Target  # noqa: E402 (import after stdout fix)


# ---------------------------------------------------------------------------
# Constantes
# ---------------------------------------------------------------------------

WEBKIT_EPOCH_OFFSET_MICROS = 11_644_473_600 * 1_000_000  # 1601->1970 em microssegundos

# Possiveis locais do Notepad++ (expanda se necessario)
NOTEPAD_PATHS = [
    r"C:\Program Files\Notepad++\notepad++.exe",
    r"C:\Program Files (x86)\Notepad++\notepad++.exe",
    os.path.expandvars(r"%LOCALAPPDATA%\Programs\Notepad++\notepad++.exe"),
    os.path.expandvars(r"%APPDATA%\Notepad++\notepad++.exe"),
]

# Encoding do arquivo de saida: utf-8-sig grava o BOM (EF BB BF)
# O Notepad++, Excel, PowerShell e VSCode reconhecem o BOM e abrem como UTF-8
OUTPUT_ENCODING = "utf-8-sig"


# ---------------------------------------------------------------------------
# Funcoes utilitarias
# ---------------------------------------------------------------------------

def webkit_to_datetime(webkit_ts: int) -> str:
    """Converte timestamp Webkit/Chrome (microsegundos desde 1601-01-01)
    para string legivel em horario de Brasilia (UTC-3)."""
    if not webkit_ts:
        return "N/A"
    try:
        ts_sec = (webkit_ts - WEBKIT_EPOCH_OFFSET_MICROS) / 1_000_000
        dt_utc = datetime(1970, 1, 1, tzinfo=timezone.utc) + timedelta(seconds=ts_sec)
        brt = timezone(timedelta(hours=-3))
        return dt_utc.astimezone(brt).strftime("%d/%m/%Y %H:%M:%S")
    except Exception:
        return str(webkit_ts)


def unix_micros_to_datetime(unix_ts: int) -> str:
    """Converte timestamp Firefox (microsegundos desde 1970-01-01)
    para string legivel em horario de Brasilia (UTC-3)."""
    if not unix_ts:
        return "N/A"
    try:
        ts_sec = unix_ts / 1_000_000
        dt_utc = datetime(1970, 1, 1, tzinfo=timezone.utc) + timedelta(seconds=ts_sec)
        brt = timezone(timedelta(hours=-3))
        return dt_utc.astimezone(brt).strftime("%d/%m/%Y %H:%M:%S")
    except Exception:
        return str(unix_ts)


def get_domain(url: str) -> str:
    """Extrai somente o dominio de uma URL, sem 'www.' e sem porta.
    URLs locais (file:///) sao marcadas como '[arquivo local]'."""
    try:
        parsed = urlparse(url)
        # URL local do sistema de arquivos
        if parsed.scheme == "file" or (not parsed.scheme and url.startswith("/")):
            return "[arquivo local]"
        netloc = parsed.netloc or parsed.path
        netloc = netloc.split(":")[0]
        if netloc.startswith("www."):
            netloc = netloc[4:]
        return netloc if netloc else url
    except Exception:
        return url


def find_e01(folder: str) -> str | None:
    """Encontra o primeiro arquivo *.E01 dentro da pasta informada."""
    p = Path(folder)
    for pattern in ("*.E01", "*.e01"):
        matches = sorted(p.glob(pattern))
        if matches:
            return str(matches[0])
    return None


def search_history_files(target: Target) -> list:
    """Busca arquivos de historico (History, places.sqlite) em /sysvol/Users/"""
    print("  [*] Buscando arquivos de historico em /sysvol/Users/ ... (isso pode demorar um pouco)")
    found_files = []
    
    try:
        users_dir = target.fs.path("/sysvol/Users")
        if not users_dir.exists():
            print("  [AVISO] Diretorio /sysvol/Users nao encontrado.")
            return found_files
            
        # Percorre os profiles em /sysvol/Users/
        for user_profile in users_dir.iterdir():
            if not user_profile.is_dir():
                continue
                
            app_data = user_profile / "AppData"
            if not app_data.exists() or not app_data.is_dir():
                continue
                
            # Busca arquivos de historico conhecidos dentro do AppData (recursivamente)
            # Extensoes/Nomes procurados: History (Chrome, Edge, Brave, Opera, etc) e places.sqlite (Firefox)
            # Para evitar percorrer tudo, iteramos recursivamente com try/except
            for entry in app_data.rglob("*"):
                try:
                    if entry.is_file():
                        name_lower = entry.name.lower()
                        if name_lower == "history" or name_lower == "places.sqlite":
                            found_files.append(entry)
                except Exception:
                    continue
                    
    except Exception as e:
        print(f"  [ERRO] Falha ao buscar arquivos: {e}")
        
    return found_files


def extract_to_temp(file_entry) -> str:
    """Extrai o arquivo do container E01 para um arquivo temporario local."""
    suffix = Path(file_entry.name).suffix or ".db"
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
    data = file_entry.open().read()
    tmp.write(data)
    tmp.close()
    return tmp.name


def query_chrome_history(db_path: str) -> list[dict]:
    """Consulta o banco SQLite do Chrome/Chromium e retorna os registros."""
    try:
        conn = sqlite3.connect(f"file:{db_path}?mode=ro&immutable=1", uri=True)
    except Exception:
        # Fallback: abre sem URI para versoes antigas do Python/SQLite
        conn = sqlite3.connect(db_path)

    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT title, visit_count, last_visit_time, url
            FROM urls
            ORDER BY last_visit_time DESC
        """)
        rows = cur.fetchall()
    except sqlite3.OperationalError as e:
        print(f"  [ERRO] Falha ao consultar historico Chrome: {e}")
        rows = []
    finally:
        conn.close()

    return [
        {
            "title":       (row["title"] or "(sem titulo)").strip(),
            "visit_count": row["visit_count"],
            "last_visit":  webkit_to_datetime(row["last_visit_time"]),
            "domain":      get_domain(row["url"]),
        }
        for row in rows
    ]


def query_firefox_history(db_path: str) -> list[dict]:
    """Consulta o banco SQLite do Firefox (places.sqlite) e retorna os registros."""
    try:
        conn = sqlite3.connect(f"file:{db_path}?mode=ro&immutable=1", uri=True)
    except Exception:
        conn = sqlite3.connect(db_path)

    conn.row_factory = sqlite3.Row
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT title, visit_count, last_visit_date, url
            FROM moz_places
            WHERE last_visit_date IS NOT NULL
            ORDER BY last_visit_date DESC
        """)
        rows = cur.fetchall()
    except sqlite3.OperationalError as e:
        print(f"  [ERRO] Falha ao consultar historico Firefox: {e}")
        rows = []
    finally:
        conn.close()

    return [
        {
            "title":       (row["title"] or "(sem titulo)").strip(),
            "visit_count": row["visit_count"],
            "last_visit":  unix_micros_to_datetime(row["last_visit_date"]),
            "domain":      get_domain(row["url"]),
        }
        for row in rows
    ]


def build_report(records: list[dict], evidence_label: str, source_label: str, logical_path: str) -> str:
    """Formata os registros como um bloco de texto legivel."""
    sep = "=" * 80
    now = datetime.now().strftime("%d/%m/%Y %H:%M:%S")

    lines = [
        sep,
        f"  HISTORICO DE NAVEGACAO",
        f"  Evidencia : {evidence_label}",
        f"  Arquivo   : {source_label}",
        f"  Caminho   : {logical_path}",
        f"  Extraido  : {now}",
        f"  Total     : {len(records)} registro(s)",
        sep,
        "",
    ]

    if not records:
        lines.append("  Nenhum registro encontrado.")
        lines.append("")
        return "\r\n".join(lines)  # CRLF para melhor visualizacao no Notepad++

    # Larguras dinamicas para alinhar as colunas
    w_domain = max((len(r["domain"]) for r in records), default=40)
    w_domain = min(max(w_domain, 30), 60)
    w_title  = max((len(r["title"])  for r in records), default=40)
    w_title  = min(max(w_title, 30), 70)

    header = (
        f"  {'DOMINIO':<{w_domain}}"
        f"  {'TITULO':<{w_title}}"
        f"  {'VISITAS':>7}"
        f"  ULTIMO ACESSO"
    )
    lines.append(header)
    lines.append("  " + "-" * (len(header) - 2))

    for r in records:
        domain = r["domain"][:w_domain]
        title  = r["title"][:w_title]
        lines.append(
            f"  {domain:<{w_domain}}"
            f"  {title:<{w_title}}"
            f"  {r['visit_count']:>7}"
            f"  {r['last_visit']}"
        )

    lines.append("")
    # CRLF para melhor visualizacao no Windows (Notepad++, WordPad, PowerShell)
    return "\r\n".join(lines)


def desktop_path() -> Path:
    """Retorna o caminho do Desktop do usuario atual."""
    return Path.home() / "Desktop"


def output_file_path(evidence_label: str) -> Path:
    """Monta o caminho do arquivo de saida no Desktop."""
    safe = re.sub(r"[^\w\-]", "_", evidence_label)
    return desktop_path() / f"historico_{safe}.txt"


def open_in_notepadpp(filepath: str) -> None:
    """Abre o arquivo no Notepad++, ou no editor padrao se nao encontrado."""
    npp = next((p for p in NOTEPAD_PATHS if Path(p).exists()), None)
    if npp:
        # -n1 vai para a 1a linha; o Notepad++ detecta o BOM e abre como UTF-8
        subprocess.Popen([npp, filepath, "-n1"])
        print(f"\n  [OK] Abrindo no Notepad++: {npp}")
    else:
        print("\n  [AVISO] Notepad++ nao encontrado. Abrindo com editor padrao...")
        os.startfile(filepath)


# ---------------------------------------------------------------------------
# Fluxo principal interativo
# ---------------------------------------------------------------------------

def main():
    print()
    print("=" * 68)
    print("       EXTRATOR DE HISTORICO E01  --  Forensic Tools")
    print("=" * 68)
    print()

    # ── 1. Pasta contendo o E01 ──────────────────────────────────────────
    while True:
        folder = input(
            "  [1/1] Informe a pasta que contem o arquivo .E01\n"
            "        (ex: F:\\MAT_207_2026)\n"
            "  > "
        ).strip().strip('"').strip("'")

        if not folder:
            print("  [ERRO] Caminho nao pode ser vazio.\n")
            continue
        if not Path(folder).is_dir():
            print(f"  [ERRO] Pasta nao encontrada: {folder}\n")
            continue
        e01_path = find_e01(folder)
        if not e01_path:
            print(f"  [ERRO] Nenhum arquivo .E01 encontrado em: {folder}\n")
            continue
        print(f"  [OK]  E01 localizado: {e01_path}\n")
        break

    evidence_label = Path(e01_path).stem

    # ── 2. Abre a imagem E01 ─────────────────────────────────────────────
    print("  [*] Abrindo imagem E01 (aguarde)...")
    try:
        target = Target.open(e01_path)
    except Exception as e:
        print(f"  [ERRO] Nao foi possivel abrir a imagem E01:\n         {e}")
        sys.exit(1)
    print("  [OK] Imagem aberta com sucesso.\n")

    # ── 3. Busca arquivos de historico ───────────────────────────────────
    found_files = search_history_files(target)
    
    if not found_files:
        print("  [ERRO] Nenhum arquivo de historico encontrado na imagem.")
        sys.exit(1)
        
    print(f"\n  [OK] Encontrados {len(found_files)} arquivo(s) de historico:\n")
    for i, f in enumerate(found_files, 1):
        print(f"    [{i}] {f}")
        
    # ── 4. Selecao do usuario ────────────────────────────────────────────
    print()
    while True:
        choice = input(
            "  Digite os numeros dos arquivos que deseja extrair (separados por espaco)\n"
            "  ou digite 'todos' para extrair todos.\n"
            "  > "
        ).strip().lower()
        
        if not choice:
            continue
            
        selected_files = []
        if choice == 'todos' or choice == 'all':
            selected_files = found_files
            break
        else:
            try:
                indices = [int(x) for x in choice.split()]
                for idx in indices:
                    if 1 <= idx <= len(found_files):
                        selected_files.append(found_files[idx - 1])
                if selected_files:
                    break
                else:
                    print("  [ERRO] Nenhum numero valido selecionado.\n")
            except ValueError:
                print("  [ERRO] Entrada invalida. Digite numeros separados por espaco ou 'todos'.\n")
                
    # ── 5. Processamento dos arquivos selecionados ───────────────────────
    out_file = output_file_path(evidence_label)
    
    for idx, file_entry in enumerate(selected_files, 1):
        logical_path = str(file_entry)
        source_label = Path(logical_path).name
        
        print(f"\n  [{idx}/{len(selected_files)}] Processando: {logical_path}")
        tmp_db = extract_to_temp(file_entry)
        
        # Define o parser com base no nome do arquivo
        if source_label.lower() == "places.sqlite":
            records = query_firefox_history(tmp_db)
        else:
            records = query_chrome_history(tmp_db)
            
        try:
            os.unlink(tmp_db)
        except OSError:
            pass
            
        print(f"  [OK] {len(records)} registro(s) encontrado(s).")
        
        report = build_report(records, evidence_label, source_label, logical_path)
        
        mode = "a" if out_file.exists() else "w"
        with open(out_file, mode, encoding=OUTPUT_ENCODING, newline="") as f:
            f.write(report)
            f.write("\r\n")

    print(f"\n  [OK] Todos os relatorios foram salvos em: {out_file}")

    # ── 6. Abre no Notepad++ ─────────────────────────────────────────────
    open_in_notepadpp(str(out_file))

    print()
    print("  Concluido! Pressione Enter para sair.")
    input()


if __name__ == "__main__":
    main()
