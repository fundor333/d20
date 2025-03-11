# Python

## Poetry

!!! Question "Requirements.txt"

    === "Problema"

        Ho bisogno di generare le dipendenze in un file requirements.txt da un progetto poetry

    === "Soluzione"

        Il comando che serve lanciare è 
    
        ``` python
        poetry export --without-hashes --format=requirements.txt > requirements.txt
        ```

        Per funzionare però necessita che sia inserito nel file __pyproject.toml__ la seguente configurazione

        ``` toml
        [tool.poetry.requires-plugins]
        poetry-plugin-export = ">=1.8"
        ```

!!! Question "Env inside project"

    === "Problema"

        Vorrei che Poetry creasse e gestisse all interno dei progetti gli env e non in uno spazio separato

    === "Soluzione"

        Questa è una configurazione cambiabile di poetry. La si cambia lanciando il seguente comando 

        ~~~ bash
        poetry config virtualenvs.in-project true
        ~~~
