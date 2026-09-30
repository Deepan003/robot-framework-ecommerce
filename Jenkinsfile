pipeline {
    agent any

    options {
        timestamps()
    }

    stages {
        stage('Install dependencies') {
            steps {
                bat 'python -m venv .venv'
                bat '.venv\\Scripts\\pip install -r requirements.txt'
            }
        }

        stage('Run Robot Framework suite') {
            steps {
                bat '.venv\\Scripts\\python -m robot --outputdir results --listener libraries/HistoryListener.py tests/'
            }
        }
    }

    post {
        always {
            // Robot's own log.html/report.html/output.xml, plus this project's
            // cross-run dashboard.html, all land in results/ and get archived
            // regardless of pass/fail so a red build still leaves evidence.
            archiveArtifacts artifacts: 'results/*.html, results/*.xml, results/*.png', allowEmptyArchive: true
        }
    }
}
