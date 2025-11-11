from __future__ import annotations

import logging
from pathlib import Path


def setup_logging(output_dir: Path, run_id: str, date_folder: str) -> Path:
    """
    Configure root logger to log to both stdout and a file.
    Returns the path to the log file.
    """
    logs_dir = output_dir / "logs" / date_folder
    logs_dir.mkdir(parents=True, exist_ok=True)
    log_path = logs_dir / f"{run_id}.log"

    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    # Clear existing handlers to avoid duplicates when re-running interactively
    for handler in list(logger.handlers):
        logger.removeHandler(handler)

    file_handler = logging.FileHandler(log_path, encoding="utf-8")
    file_formatter = logging.Formatter(
        "%(asctime)s [%(levelname)s] %(name)s - %(message)s", datefmt="%Y-%m-%d %H:%M:%S"
    )
    file_handler.setFormatter(file_formatter)
    logger.addHandler(file_handler)

    console_handler = logging.StreamHandler()
    console_formatter = logging.Formatter("%(message)s")
    console_handler.setFormatter(console_formatter)
    logger.addHandler(console_handler)

    logger.debug("Logging configured. Log file: %s", log_path)
    return log_path


