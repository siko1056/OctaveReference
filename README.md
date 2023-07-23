# OctaveReference

A self-contained documentation system for Octave and Octave Packages.

[![OctaveReference](./doc/icon.png)](./doc/icon.png)

## Documentation generation workflow

```mermaid
flowchart TB
  api;
  web_client_a[web client \n A];
  web_client_b[web client \n B];
  web_client_x[web client \n ...];
  db[(SQLite)];
  image_folder[(image_folder)];
  packages[(Octave Packages)];
  change_watcher;

  subgraph docstring_collector
    direction TB
    unpack["download and install package"];
    foreach["for each symbol"];
    text["get helptext"];
    demos["get demos"];
    figures["get demo figures"];

    unpack --> foreach;
    foreach --> text & demos & figures;
  end

  packages -->|pull package| docstring_collector;
  change_watcher -->|watch periodically \n for changes| packages;
  change_watcher -->|package information| docstring_collector;
  docstring_collector -->|store collected \n helptext and demos| db;
  docstring_collector -->|store collected \n figures|image_folder;
  db & image_folder -->|queries| api;
  web_client_a & web_client_b & web_client_x -->|JSON query| api;
  api -->|JSON response| web_client_a & web_client_b & web_client_x;

  classDef textLeft text-align: left;
  class docstring_collector textLeft;
  
```

> [Flowchart syntax](https://mermaid.js.org/syntax/flowchart.html)

## Database schema

- package
  - id: INTEGER PRIMARY KEY ASC
  - name: TEXT
  - version: TEXT
  - archive_source: TEXT
  - archive_sha256: TEXT
  - created_unix_time: INTEGER

- symbol
  - id: INTEGER PRIMARY KEY ASC
  - FOREIGN KEY(artifact_id) REFERENCES package(id)
  - name: TEXT
  - artifact_relative_path: TEXT
  - doc_h1: TEXT
  - doc: TEXT

- demo
  - id: INTEGER PRIMARY KEY ASC
  - FOREIGN KEY(symbol_id) REFERENCES symbol(id)
  - order: INTEGER
  - code: TEXT

- figure
  - id: INTEGER PRIMARY KEY ASC
  - FOREIGN KEY(demo_id) REFERENCES demo(id)
  - order: INTEGER
  - file_name: TEXT
