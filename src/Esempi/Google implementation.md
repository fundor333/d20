# Implementazione di servizi Google in Python

## Python e scrivere in fondo a un foglio di calcolo Google

``` python
import datetime
import logging
from typing import List
import pygsheets

SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
]
SERVICE_ACCOUNT_FILE = "account.json"


def add_to_sheet(spreadsheet_id: int, worksheet_title:str, data=list[dict]):

    client = pygsheets.authorize(service_file=SERVICE_ACCOUNT_FILE)
    sheet = client.open_by_key(spreadsheet_id)

    wks = sheet.worksheet_by_title(worksheet_title)
    all_values = wks.get_all_values()

    i = 0
    for e in all_values:
        if "".join(e) != "":
            i += 1

    for element in data:
        wks.insert_rows(
            i,
            values=[
                element['col1'],
                element['col2'],
                element['col3'],
                element['col4'],
            ],
            inherit=True,
        )
        done.append(element.id)
        i += 1
```
