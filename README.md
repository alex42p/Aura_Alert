
# Aura Alert

Aura Alert is a Flutter application designed to visualize biometric readings such as heart rate, skin temperature, and oxygen level. The app uses a local SQLite database to store and query readings, and displays them in interactive charts.

## Project Structure and File Breakdown

### lib/main.dart
**Purpose:** Entry point of the application. Sets up the Flutter app, theme, and dashboard.

- **MyApp**: StatelessWidget that initializes the MaterialApp with a custom theme and sets the home to `DashboardPage`.
- **DashboardPage**: StatefulWidget that serves as the main dashboard. It displays three biometric charts (Heart Rate, Skin Temperature, O₂ Level) using the `BiometricChart` widget.
- **_DashboardPageState**:
	- **DatabaseService _db**: Instance of the database service for querying readings.
	- **_loader(type, from, to)**: Loads readings of a given type from the database within a date range.
	- **build(context)**: Builds the dashboard UI, including the app bar and a grid of biometric charts.

### lib/models/biometric_reading.dart
**Purpose:** Defines the data model for a biometric reading.

- **BiometricReading**: Represents a single biometric reading.
	- **Fields**:
		- `id`: Optional integer ID (primary key in the database).
		- `timestamp`: DateTime of the reading.
		- `value`: Numeric value of the reading.
		- `type`: String indicating the type ('hr', 'temp', 'o2').
	- **toMap()**: Converts the reading to a map for database storage.
	- **fromMap(m)**: Factory constructor to create a reading from a database map.

### lib/services/database_service.dart
**Purpose:** Handles all database operations using SQLite via sqflite.

- **DatabaseService**: Singleton service for database access.
	- **_instance**: Singleton instance.
	- **_db**: Internal reference to the database.
	- **database**: Getter that initializes and returns the database.
	- **_initDB(fileName)**: Initializes the database file and creates tables.
	- **_onCreate(db, version)**: Creates the `readings` table if it doesn't exist.
	- **insertReading(r)**: Inserts a new `BiometricReading` into the database.
	- **queryReadings({type, from, to})**: Queries readings by type and optional date range.
	- **close()**: Closes the database connection.

### lib/widgets/biometric_chart.dart
**Purpose:** UI widget for displaying biometric readings in a chart.

- **BiometricChart**: StatefulWidget that displays a chart for a specific biometric type.
	- **title**: Chart title (e.g., 'Heart Rate (BPM)').
	- **loader**: Function to load readings for a given date range.
- **_BiometricChartState**:
	- **_range**: Selected chart range (last 24h, 7d, 30d, all).
	- **_future**: Future for loading readings.
	- **_loadForRange(r)**: Loads readings for the selected range.
	- **_toSpots(data)**: Converts readings to chart points.
	- **build(context)**: Builds the chart UI, including title, range selector, and chart (using fl_chart).

## Program Flow (from main.dart)
1. **App Initialization**: `main()` ensures Flutter bindings are initialized and runs `MyApp`.
2. **Dashboard Display**: `MyApp` sets up the MaterialApp and shows `DashboardPage`.
3. **Chart Loading**: `DashboardPage` creates three `BiometricChart` widgets, each with a loader function that queries the database for readings of a specific type.
4. **Database Access**: The loader function in `DashboardPage` uses `DatabaseService` to query readings from the local SQLite database.
5. **Chart Rendering**: Each `BiometricChart` fetches data for the selected range and displays it using fl_chart. If no data is available, a message or loading indicator is shown.
6. **User Interaction**: Users can change the chart range using a dropdown, which reloads the chart data.

## Notes
- The app currently does not have a backend or external data source; all data is stored locally.
- The database schema is defined in `database_service.dart` and consists of a single `readings` table.
- The UI is responsive and uses cards and charts for a modern look.

---
This README provides a detailed breakdown of each source file and the overall program flow. For further details, refer to the code comments and documentation within each file.
