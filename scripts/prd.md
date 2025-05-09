<context>
# Overview

The Personal Finance Manager is a web-based application designed for individuals and families to manage their personal finances in an organized and clear way. It solves the problem of fragmented and manual financial tracking by centralizing assets, debts, transactions, budgets, and bills into a single, easy-to-use platform. 

The system helps users:
- Track net worth and asset value
- Record and analyze income and expenses
- Set and monitor monthly budgets
- Manage recurring bills and subscriptions
- Collaborate with family members for shared financial oversight

# Core Features

## Net Worth Dashboard (Done)
- **What it does**: Displays net worth (assets - debts) and its variation over time.
- **Why it's important**: Gives users a clear view of their financial health.
- **How it works**: Aggregates balances from all assets and debts. Allows drill-down into asset categories.

## Asset and Debt Management (Done)
- **What it does**: Allows users to manually or automatically track assets and debts.
- **Why it's important**: Ensures net worth calculation is accurate and assets are up to date.
- **How it works**: Users can add/edit assets, categorize them, and view activity/history for each.

## Transaction Management (Done)
- **What it does**: Tracks all expenses, income, and transfers.
- **Why it's important**: Enables users to understand where money is coming from and going.
- **How it works**: Transactions can be manually added, imported from bank statements or CSVs, and eventually synced from banks. Categorization and editing supported.

## Budgeting (Done)
- **What it does**: Allows users to set monthly budgets per category.
- **Why it's important**: Helps users control and plan their spending.
- **How it works**: Monthly budgets are user-defined and tracked against actual spending. Overspending is flagged but not carried over.

## Advanced Envelope Budgeting (Planned)
- **What it does**: Provides a proactive budgeting system where users allocate funds into category envelopes and track spending against them.
- **Why it's important**: Helps users enforce discipline by limiting spending to what is allocated, unlike simple budget tracking.
- **How it works**:
  - Users manually allocate funds into envelopes by category.
  - Expenses reduce the allocated amount as they are categorized.
  - Optionally, leftover funds can carry over to the next month.

## Bills and Subscriptions (Partial)
- **What it does**: Manages recurring expenses like subscriptions, bills, and debt/loan payments.
- **Why it's important**: Helps users avoid missed payments and track debt payoff automatically.
- **How it works**: 
  - Users add bills with due dates, mark them as paid, pause them, and receive email reminders.
  - **New**: Bills can be categorized as Normal Bill, Loan/Debt Payment, or Other.
  - When a Loan/Debt Payment bill is marked as paid, it automatically reduces the balance of the corresponding debt in the system.

## Collaboration (Done)
- **What it does**: Enables sharing the account with family members.
- **Why it's important**: Allows joint financial management.
- **How it works**: Family members can be invited to view shared financial data.

## Calendar View (Planned)
- **What it does**: Provides a visual representation of upcoming financial obligations.
- **Why it's important**: Helps users plan cash flow and avoid surprises.
- **How it works**:
  - Displays bills, debt payments, and other reminders in a calendar format.
  - Allows filtering and marking items as paid directly from the calendar.
  - Not planned for MVP but considered for future versions.

# User Experience

## User Personas
- Primary: Individuals and families who want to manage their personal finances.
- Secondary: Family members invited for visibility (read-only at this stage).

## Key User Flows
- Adding assets and debts and seeing them reflected in net worth.
- Importing transactions and categorizing them.
- Creating budgets and monitoring overspending.
- Adding bills and receiving reminders.
- Inviting family members.

## UI/UX Considerations
- Simple and clean interface with side navigation.
- Graphical representation of net worth and budgets.
- Color-coded categories for clarity.
- Easy to manage and edit transactions, assets, bills.
</context>
<PRD>
# Technical Architecture

## 1. System Components
- **Web Application (Ruby on Rails)**
  - Handles all business logic, user authentication, and serves the main UI.
  - Uses Hotwire (Turbo/Stimulus) for SPA-like interactivity.
- **Background Jobs**
  - Managed by Sidekiq and Redis.
  - Handles data syncing, background processing, and scheduled tasks (e.g., daily syncs).
- **Asset Pipeline**
  - Uses Propshaft for asset management.
  - TailwindCSS for styling, with a custom design system.
- **External Data Providers**
  - Integrates with Plaid for bank data.
  - Integrates with Stripe for payments.
  - Uses Synth (custom API) for market data.

## 2. Data Models
- **User**: Belongs to a Family; can be admin or member.
- **Family**: Central entity; owns accounts, preferences, and subscriptions.
- **Account**: Represents a financial account (checking, investment, property, etc.).
  - Delegated types: Depository, Investment, Crypto, Property, Vehicle, CreditCard, Loan, OtherAsset, OtherLiability.
  - Fields: `balance`, `currency`, `classification` (asset/liability), etc.
- **Balance**: Daily snapshot of an account’s value.
- **Holding**: For investment accounts; tracks security, quantity, price, and date.
- **Entry**: Any record that modifies an account’s balance or holdings.
  - Types: Valuation, Transaction, Trade.
- **Transfer**: Represents money movement between accounts.
- **PlaidItem**: Represents a connection to Plaid; links to PlaidAccounts and internal Accounts.
- **Sync**: Audit record for background sync operations.

## 3. APIs and Integrations
- **Plaid API**: For fetching and syncing user bank data.
- **Stripe API**: For managing subscriptions and payments.
- **Synth API**: For market and security price data.
- **Internal APIs**: Rails controllers expose endpoints for the web UI and background jobs.
- **Provider Registry**: Abstracts and manages third-party data providers for concepts like exchange rates and security prices.

## 4. Infrastructure Requirements
- **Hosting**: Can run in “managed” (hosted) or “self-hosted” (Docker Compose) mode.
- **Database**: PostgreSQL.
- **Background Jobs**: Sidekiq with Redis.
- **Asset Management**: Propshaft, TailwindCSS.
- **Environment Variables**: Used for API keys and sensitive config (see `.env` or `.cursor/mcp.json`).
- **Configuration**: Most settings in `.taskmasterconfig` (AI models, logging, etc.).
- **Daily Syncs**: Automated via background jobs, orchestrated by the Family model.

## References
- [project-design.mdc](mdc:.cursor/rules/project-design.mdc) — for detailed architecture and data flow.
- [project-conventions.mdc](mdc:.cursor/rules/project-conventions.mdc) — for code organization and best practices.
- [schema.rb](mdc:db/schema.rb) — for authoritative data model structure.

## System Components
- Frontend: Web application (React or similar)
- Backend: API server handling data models, business logic, authentication
- Database: Stores user data, assets, debts, transactions, budgets, bills
- Notifications service: Handles email reminders for bills
- Import service: Parses CSV and bank statements

## Data Models
- User
- Asset
- Debt
- Transaction
- Budget
- Bill
- Category
- Family member invite

## APIs and Integrations
- CSV/Bank statement import API
- Future: Bank sync API
- Email service for reminders

## Infrastructure Requirements
- Cloud hosting (AWS, Vercel, or similar)
- Database (PostgreSQL recommended)
- Background job processing (for reminders)

# Development Roadmap

## MVP Requirements
- User authentication and single account per user
- Asset and debt management (add/edit/delete)
- Transaction management (manual and CSV import)
- Budgeting module (monthly budget set and actual tracking)
- Bills and subscriptions module (recurring bills, mark paid, email reminders)
- Dashboard (net worth and spending summary)
- Family member invites (read-only)

## Future Enhancements
- Bank sync integrations (Plaid or similar)
- Push notifications
- Advanced reporting/export
- Multiple user roles
- More granular bill rules (auto-matching with transactions)

# Logical Dependency Chain

## Foundation (Already Implemented)
- User authentication and single user account support
- Core data models: User, Asset, Debt, Transaction, Budget, Bill, Category
- Manual entry and editing capabilities for assets, debts, transactions, and bills

## Core User Experience (Already Implemented)
- Dashboard with net worth calculation and graph
- Transaction management (manual entry, import from CSV, categorization, transfers)
- Budgeting module with monthly budgets, tracking, and overspending indicators
- Bills and subscriptions module with recurring billing logic, mark as paid, paused states
- Email notifications for bill reminders
- Asset/debt drill-down and balance tracking with activity log

## Extended and Supporting Features (Already Implemented)
- Family member invites (read-only collaboration)
- Custom category management
- Multi-currency support per transaction
- UI for managing transactions, budgets, bills, and assets in an intuitive way

# Risks and Mitigations

## Technical Challenges
- Multi-currency support can lead to calculation complexity → standardize on transaction currency, convert only at reporting level.
- Bank sync integration is planned but complex → defer to post-MVP.

## MVP Focus
- Too many features could delay release → focus MVP on manual data entry, budgets, bills, and dashboard.

## Resource Constraints
- Email notification infrastructure → start with basic transactional email provider (e.g. Postmark) for reminders.

# Appendix

- No research findings included — screenshots shared show full prototype.
- Technical specifications mostly aligned with current app architecture.
</PRD>