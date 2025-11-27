# AI/ML Expert with Phitron Batch 01

This repository contains educational materials, code examples, and projects developed during the AI/ML Expert course (Batch 01) offered by Phitron. It covers fundamental concepts from Python programming for machine learning to practical ML/DL implementations.


## Repository Structure

### Core Directories
- **Machine Learning/**: Contains machine learning project architectures, documentation, and related code.
  - `architecture_documentation.md`: Documentation template for ML project architectures (currently in initial state with module/class/function counts set to 0).
- **Python For ML/**: Focuses on Python programming fundamentals tailored for machine learning.
  - `sample.txt`: Text samples for string manipulation and NLP practice exercises.
  - `sample2.txt`: Concatenated text data derived from `sample.txt` (used for advanced string processing tasks).


### Key Root Files
- **`.gitignore`**: Configures files/directories to be ignored by Git, including:
  - Jupyter Notebook checkpoints and runtime files
  - Python cache/compiled files
  - Virtual environment folders
  - IDE settings (VSCode, IntelliJ)
  - Large data files (CSV, H5, ZIP, etc.)
  - Logs, temporary files, and credentials
  - Generated outputs (plots, reports, PDFs)

- **`requirements.txt`**: Comprehensive list of Python packages used in the course, including:
  - ML/DL frameworks (scikit-learn, TensorFlow, PyTorch-related tools)
  - Data processing (pandas, numpy, pyarrow)
  - Visualization (matplotlib, altair)
  - Web frameworks (Django, FastAPI, Flask)
  - Computer vision (OpenCV, dlib, face-recognition)
  - NLP (nltk, transformers, tiktoken)
  - Utilities (loguru, tqdm, python-dotenv)

- **`run.bat`**: Windows batch script for simplified Git operations:
  - Checks for Git installation and repository initialization
  - Stages changes, prompts for commit messages (auto-generates if empty)
  - Shows current branch and pushes to specified branch (defaults to current branch)
  - Includes visual feedback with colored icons and progress indicators


## Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Tanvir-yzu/AI_ML-Expert-With-Phitron-Batch-01.git
   cd AI_ML-Expert-With-Phitron-Batch-01
   ```

2. **Create and Activate Virtual Environment**
   ```bash
   # Create virtual environment
   python -m venv venv

   # Activate on Windows
   venv\Scripts\activate

   # Activate on macOS/Linux
   source venv/bin/activate
   ```

3. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```


## Git Automation with `run.bat`

A user-friendly script to streamline Git workflows on Windows:
- Automatically handles repository initialization (if missing)
- Stages all changes and prompts for commit messages
- Displays current branch and simplifies pushing to remote

Run the script:
```cmd
run.bat
```


## Notes

- **Data Handling**: Large data files and outputs are ignored by default (see `.gitignore`) to keep the repository lightweight.
- **Documentation**: The `architecture_documentation.md` in the `Machine Learning` directory is a template intended to track module dependencies and project structure as projects evolve.
- **Practice Files**: `sample.txt` and `sample2.txt` in `Python For ML` are used for hands-on practice with string operations, text processing, and basic NLP tasks.






