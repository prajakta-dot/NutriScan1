# NutriScan 🌿

**A Smart Food Nutrition Analysis Application**

NutriScan is a mobile application that helps users understand the nutritional value of packaged food products through product search and barcode scanning.

## 🛠️ Technologies Used
- Frontend: Flutter and Dart
- Backend: Python and FastAPI
- Database: MySQL
- Barcode Scanner: mobile_scanner
- External Data Source: Open Food Facts

## ✨ Features
- Search food products by name or brand.
- Scan product barcodes.
- View nutritional information.
- Calculate project-specific nutrition scores.
- Filter products based on nutritional values.
- Compare food products.
- Get smarter food alternatives through recommendations.

## 📁 Project Structure
- `main.py` – FastAPI backend
- `nutriscan_app/` – Flutter mobile application
- `nutriscan_database.sql` – MySQL database export
- `packaged_foods_india.csv` – Food product dataset
- `requirements.txt` – Python dependencies

## 🚀 Backend Setup

1. Install Python and MySQL.
2. Create a MySQL database named `nutriscan`.
3. Import the database:

   `mysql -u root -p nutriscan < nutriscan_database.sql`

4. Install dependencies:

   `python -m pip install -r requirements.txt`

5. Set the MySQL password:

   `export MYSQL_PASSWORD='your_mysql_password'`

6. Start the backend:

   `python -m uvicorn main:app --reload --host 0.0.0.0 --port 8001`

7. Open the API documentation:

   `http://127.0.0.1:8001/docs`

## 📱 Frontend Setup

1. Install Flutter and Android Studio.
2. Open the `nutriscan_app` folder.
3. Install Flutter dependencies:

   `flutter pub get`

4. Configure the backend API address in the Flutter application to match your computer's network address.
5. Run the application:

   `flutter run`

## 👥 Team Project

This repository is intended for collaborative development and contributions from NutriScan team members.

---

**NutriScan – Making Food Choices Smarter! 🌿**