# GuideU Flutter MVVM Architecture

This is a simplified view of the Flutter app structure under `frontend/guide_u_flutter/lib`.

```mermaid
flowchart LR
  subgraph Views["Views"]
    direction TB
    Login["LoginScreen"]
    MainPage["HandbookMainPage"]
    HandbookPages["Handbook screens"]
    SearchPage["Search screen"]
    ChatPage["Chatbot"]
    SavedPage["Saved articles"]
    ReportPages["Report pages"]
  end

  subgraph ViewModels["ViewModels"]
    direction TB
    LoginVM["LoginViewModel"]
    MainVM["HandbookMainViewModel"]
    SearchVM["HandbookSearchViewModel"]
    ChatVM["HandbookChatbotViewModel"]
    SavedVM["SavedArticlesViewModel"]
    ReportVMs["Incident / LostFound ViewModels"]
  end

  subgraph Models["Models"]
    direction TB
    HandbookArticle["HandbookArticle"]
    SavedArticle["SavedArticle"]
    ReportModels["report_models"]
    StudentGovernment["student_government"]
  end

  Views --> ViewModels --> Models

  Login --> LoginVM
  MainPage --> MainVM
  HandbookPages --> MainVM
  SearchPage --> SearchVM
  ChatPage --> ChatVM
  SavedPage --> SavedVM
  ReportPages --> ReportVMs

  MainVM --> HandbookArticle
  SearchVM --> HandbookArticle
  SavedVM --> SavedArticle
  ReportVMs --> ReportModels
  MainVM --> StudentGovernment
```

## Readout

- Views render the UI.
- ViewModels hold state and business logic.
- Models represent the data used by the app, including handbook content, saved items, reports, and student government data.
- Most of the app flows from Views to ViewModels, then down to Models and external services behind the scenes.
