# Taskey - Task Tracker & SLA Monitoring System (Group 8)

A modern, cross-platform Flutter application engineered for software teams to track project tasks and monitor Service Level Agreements (SLAs) in real time.

---

## Features

- **Real-Time SLA Classification Engine**: Automatically evaluates task deadlines across 5 business rules (`On Track`, `At Risk`, `Overdue`, and `Completed`), calculating priority-based risk windows and deadline burn rates.
- **Custom Data Visualization**: Interactive Donut Chart built using Flutter's `CustomPaint` and mathematical arc calculations—no external charting packages required.
- **Dual-Axis Dashboard Layout**: Horizontal carousel of high-priority featured task cards coupled with a vertical Task Overview breakdown and Recent Activity feed.
- **Form Validation & Secure Inputs**: Robust input validation powered by regular expressions for names, RFC-compliant emails, and complex password rules.
- **Dynamic Team Management**: Automatically detects the active authenticated user and places them as the **Project Lead `(You)`** with self-assignment privileges and team CRUD capabilities.
- **Local Persistence & Audit Trail**: Full JSON serialization (`toJson` / `fromJson`) storing tasks, members, and historical activity events locally.

---

## Project Structure

```
lib/
├── main.dart                  # Application entry point and theme binding
├── routes.dart                # Centralized named route generator
├── models/
│   ├── app_activity.dart      # Audit trail activity model
│   ├── task.dart              # Task domain model with JSON serialization
│   └── team_member.dart       # Team member model and role colors
├── screens/
│   ├── auth/
│   │   ├── signin_screen.dart   # Sign-in with Remember Me
│   │   ├── signup_screen.dart   # Sign-up with regex validation
│   │   └── welcome_screen.dart  # Onboarding welcome landing
│   ├── dashboard/
│   │   └── dashboard_screen.dart # Main hub, dual-axis layout, task overview
│   ├── profile/
│   │   └── profile_screen.dart   # User and member profile with live stats
│   ├── tasks/
│   │   ├── task_details_screen.dart # Schedule timeline and status modal
│   │   ├── task_form_screen.dart    # Create & edit tasks with date pickers
│   │   ├── task_list_screen.dart    # Searchable and filterable task list
│   │   └── task_status_screen.dart  # Donut chart and SLA metrics breakdown
│   └── team/
│       ├── create_team_screen.dart  # Create, edit, and delete teams
│       └── team_members_screen.dart # Team directory and member workload
├── services/
│   ├── auth_service.dart      # User session and authentication management
│   ├── sla_service.dart       # Core SLA classification engine and helpers
│   └── storage_service.dart   # Persistent local JSON data store
├── theme/
│   └── app_theme.dart         # Unified color palette, typography, and styling
├── utils/
│   └── validators.dart        # Reusable input validation rules
└── widgets/
    ├── status_badge.dart      # Semantic status, SLA, and priority badges
    └── task_card.dart         # Reusable task card with SLA progress bar
```

---

## Getting Started

### Prerequisites
- Flutter SDK (v3.13.0 or newer)
- Dart SDK (v3.1.0 or newer)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Eelaf-Adam/task_tracker_group8.git
   cd task_tracker_group8
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

### Running Tests
Execute unit and widget tests:
```bash
flutter test
```

---

## Team contributions and branches

Every member works on their own branch and merges through a pull request into `main`.

| Member | Branch | Key responsibilities |
| :--- | :--- | :--- |
| **Eelaf Abuelgasim Abdalla Adam** | `eelaf-branch` | App foundation, authentication, routing, form validation, app theme |
| **Benjamin Niyomurinzi** | `member2-fix-task-list` `member2-task-data`| Task model, `StorageService` (local persistence), create/edit task form and validation |
| **Dianah Shimwa Gasasira** | `feature/task-management-sla` | SLA classification engine, task list (search and filters), task details, task status screen, reusable task widgets |
| **Kenny Gael Ishimwe Gatete** | `kenny-screens` | Dashboard architecture, dual-axis layout, team and profile views |

The group contribution tracker linked at the top records each member's tasks, review status and meetings.

---
