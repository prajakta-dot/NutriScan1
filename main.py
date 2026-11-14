
import os
import requests
import pymysql

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI(title="NutriScan API")


# Allow frontend connections
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# MySQL connection
def get_connection():
    password = os.getenv("MYSQL_PASSWORD")

    if not password:
        raise RuntimeError("MYSQL_PASSWORD environment variable is not set")

    return pymysql.connect(
        host="localhost",
        user="root",
        password=password,
        database="nutriscan",
        port=3306,
        cursorclass=pymysql.cursors.DictCursor
    )


@app.get("/")
def home():
    return {"message": "NutriScan API is running!"}


# --------------------------------
# 1. BARCODE PRODUCT LOOKUP
# --------------------------------

@app.get("/product/{barcode}")
def get_product(barcode: str):

    barcode = barcode.strip()

    if not barcode.isdigit():
        raise HTTPException(
            status_code=400,
            detail="Invalid barcode"
        )

    conn = get_connection()

    try:
        with conn.cursor() as cursor:

            # Search MySQL first
            cursor.execute(
                "SELECT * FROM products WHERE barcode = %s",
                (barcode,)
            )

            result = cursor.fetchone()

            if result:
                return {
                    "source": "MySQL",
                    "product": result
                }

            # Search Open Food Facts
            url = (
                f"https://world.openfoodfacts.org/"
                f"api/v2/product/{barcode}.json"
            )

            headers = {
                "User-Agent": "NutriScan/1.0"
            }

            try:
                response = requests.get(
                    url,
                    headers=headers,
                    timeout=20
                )

                if response.status_code == 404:
                    raise HTTPException(
                        status_code=404,
                        detail="Product not found in Open Food Facts"
                    )

                response.raise_for_status()

            except requests.RequestException:
                raise HTTPException(
                    status_code=502,
                    detail="Open Food Facts service unavailable"
                )

            data = response.json()

            if data.get("status") != 1:
                raise HTTPException(
                    status_code=404,
                    detail="Product not found"
                )

            product = data.get("product", {})
            nutrition = product.get("nutriments", {})

            # Safely convert numeric values
            def get_number(value):
                try:
                    return float(value) if value is not None else None
                except (ValueError, TypeError):
                    return None

            sodium = get_number(nutrition.get("sodium_100g"))
            cholesterol = get_number(
                nutrition.get("cholesterol_100g")
            )
            calcium = get_number(nutrition.get("calcium_100g"))
            iron = get_number(nutrition.get("iron_100g"))

            details = {
                "barcode": barcode,
                "product_name": product.get("product_name"),
                "brand_name": product.get("brands"),
                "category": product.get("categories"),
                "ingredients": product.get("ingredients_text"),
                "serving_size_g": 100,

                "calories_kcal": get_number(
                    nutrition.get("energy-kcal_100g")
                ),
                "carbohydrates_g": get_number(
                    nutrition.get("carbohydrates_100g")
                ),
                "proteins_g": get_number(
                    nutrition.get("proteins_100g")
                ),
                "total_fat_g": get_number(
                    nutrition.get("fat_100g")
                ),
                "saturated_fat_g": get_number(
                    nutrition.get("saturated-fat_100g")
                ),
                "trans_fat_g": get_number(
                    nutrition.get("trans-fat_100g")
                ),
                "sugar_g": get_number(
                    nutrition.get("sugars_100g")
                ),

                "sodium_mg": (
                    sodium * 1000 if sodium is not None else None
                ),
                "dietary_fiber_g": get_number(
                    nutrition.get("fiber_100g")
                ),
                "cholesterol_mg": (
                    cholesterol * 1000
                    if cholesterol is not None else None
                ),
                "calcium_mg": (
                    calcium * 1000
                    if calcium is not None else None
                ),
                "vitamin": None,
                "iron_mg": (
                    iron * 1000 if iron is not None else None
                )
            }

            # Save fetched product in MySQL
            columns = list(details.keys())

            sql = f"""
                INSERT INTO products ({', '.join(columns)})
                VALUES ({', '.join(['%s'] * len(columns))})
                ON DUPLICATE KEY UPDATE
                    product_name = VALUES(product_name),
                    brand_name = VALUES(brand_name),
                    calories_kcal = VALUES(calories_kcal)
            """

            cursor.execute(sql, tuple(details.values()))
            conn.commit()

            return {
                "source": "Open Food Facts",
                "message": "Product fetched and saved successfully",
                "product": details
            }

    finally:
        conn.close()


# --------------------------------
# 2. INDIAN DATASET NUTRITION FILTER
# --------------------------------

@app.get("/products/filter")
def filter_products(
    max_calories: float = Query(None, ge=0),
    max_sugar: float = Query(None, ge=0),
    max_fat: float = Query(None, ge=0),
    min_protein: float = Query(None, ge=0),
    max_sodium: float = Query(None, ge=0),
    category: str = Query(None),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0)
):

    conn = get_connection()

    try:
        conditions = []
        values = []

        if max_calories is not None:
            conditions.append("calories_kcal <= %s")
            values.append(max_calories)
            conditions.append("calories_kcal IS NOT NULL")

        if max_sugar is not None:
            conditions.append("sugar_g <= %s")
            values.append(max_sugar)
            conditions.append("sugar_g IS NOT NULL")

        if max_fat is not None:
            conditions.append("total_fat_g <= %s")
            values.append(max_fat)
            conditions.append("total_fat_g IS NOT NULL")

        if min_protein is not None:
            conditions.append("proteins_g >= %s")
            values.append(min_protein)
            conditions.append("proteins_g IS NOT NULL")

        if max_sodium is not None:
            conditions.append("sodium_mg <= %s")
            values.append(max_sodium)
            conditions.append("sodium_mg IS NOT NULL")

        if category:
            conditions.append("category LIKE %s")
            values.append(f"%{category.strip()}%")

        # Build WHERE clause
        where_clause = (
            "WHERE " + " AND ".join(conditions)
            if conditions else ""
        )

        with conn.cursor() as cursor:

            # Count ALL matching products
            count_sql = f"""
                SELECT COUNT(*) AS total
                FROM products
                {where_clause}
            """

            cursor.execute(count_sql, tuple(values))
            total_results = cursor.fetchone()["total"]

            # Fetch only the requested page
            sql = f"""
                SELECT
                    product_id,
                    barcode,
                    product_name,
                    brand_name,
                    category,
                    sub_category,
                    serving_size_g,
                    calories_kcal,
                    sugar_g,
                    total_fat_g,
                    proteins_g,
                    sodium_mg,
                    price_inr
                FROM products
                {where_clause}
                ORDER BY product_name
                LIMIT %s OFFSET %s
            """

            cursor.execute(
                sql,
                tuple(values + [limit, offset])
            )

            products = cursor.fetchall()

        return {
            "source": "NutriScan MySQL Dataset",
            "total_results": total_results,
            "returned_results": len(products),
            "limit": limit,
            "offset": offset,
            "filters_applied": {
                "max_calories": max_calories,
                "max_sugar": max_sugar,
                "max_fat": max_fat,
                "min_protein": min_protein,
                "max_sodium": max_sodium,
                "category": category
            },
            "products": products
        }

    finally:
        conn.close()

# --------------------------------
# 3. PRODUCT SEARCH BY NAME / BRAND
# --------------------------------

@app.get("/products/search")
def search_products(
    q: str = Query(..., min_length=2, max_length=100),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0)
):

    conn = get_connection()

    try:
        search_value = f"%{q.strip()}%"

        conditions = """
            WHERE product_name LIKE %s
               OR brand_name LIKE %s
               OR category LIKE %s
        """

        search_values = [
            search_value,
            search_value,
            search_value
        ]

        with conn.cursor() as cursor:

            # Count matching products
            count_sql = f"""
                SELECT COUNT(*) AS total
                FROM products
                {conditions}
            """

            cursor.execute(count_sql, tuple(search_values))
            total_results = cursor.fetchone()["total"]

            # Fetch matching products
            sql = f"""
                SELECT
                    product_id,
                    barcode,
                    product_name,
                    brand_name,
                    category,
                    sub_category,
                    serving_size_g,
                    calories_kcal,
                    sugar_g,
                    total_fat_g,
                    proteins_g,
                    sodium_mg,
                    price_inr
                FROM products
                {conditions}
                ORDER BY product_name
                LIMIT %s OFFSET %s
            """

            cursor.execute(
                sql,
                tuple(search_values + [limit, offset])
            )

            products = cursor.fetchall()

        return {
            "total_results": total_results,
            "returned_results": len(products),
            "search_query": q,
            "limit": limit,
            "offset": offset,
            "products": products
        }

    finally:
        conn.close()

# --------------------------------
# 4. NUTRITION SCORE
# --------------------------------

@app.get("/products/{product_id}/nutrition-score")
def nutrition_score(product_id: int):

    conn = get_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    product_id,
                    product_name,
                    serving_size_g,
                    calories_kcal,
                    sugar_g,
                    saturated_fat_g,
                    sodium_mg,
                    proteins_g,
                    dietary_fiber_g
                FROM products
                WHERE product_id = %s
                """,
                (product_id,)
            )

            product = cursor.fetchone()

        if not product:
            raise HTTPException(
                status_code=404,
                detail="Product not found"
            )

        serving = product["serving_size_g"]

        if not serving or serving <= 0:
            raise HTTPException(
                status_code=422,
                detail="Valid serving size is unavailable"
            )

        # Convert available values to per 100g
        def per_100g(value):
            if value is None:
                return None
            return float(value) * 100 / float(serving)

        calories = per_100g(product["calories_kcal"])
        sugar = per_100g(product["sugar_g"])
        sat_fat = per_100g(product["saturated_fat_g"])
        sodium = per_100g(product["sodium_mg"])
        protein = per_100g(product["proteins_g"])
        fiber = per_100g(product["dietary_fiber_g"])

        missing = []

        required = {
            "calories": calories,
            "sugar": sugar,
            "saturated_fat": sat_fat,
            "sodium": sodium
        }

        for name, value in required.items():
            if value is None:
                missing.append(name)

        if missing:
            return {
                "product_id": product_id,
                "product_name": product["product_name"],
                "nutrition_score": None,
                "rating": "Insufficient data",
                "missing_nutrients": missing
            }

        # Penalty points
        penalty = 0

        if calories > 400:
            penalty += 20
        elif calories > 300:
            penalty += 15
        elif calories > 200:
            penalty += 10
        elif calories > 100:
            penalty += 5

        if sugar > 22.5:
            penalty += 20
        elif sugar > 15:
            penalty += 15
        elif sugar > 5:
            penalty += 10
        elif sugar > 1:
            penalty += 5

        if sat_fat > 5:
            penalty += 15
        elif sat_fat > 2:
            penalty += 10
        elif sat_fat > 1:
            penalty += 5

        if sodium > 600:
            penalty += 15
        elif sodium > 400:
            penalty += 10
        elif sodium > 120:
            penalty += 5

        # Bonus points
        bonus = 0

        if protein is not None:
            if protein >= 10:
                bonus += 10
            elif protein >= 5:
                bonus += 5

        if fiber is not None:
            if fiber >= 6:
                bonus += 10
            elif fiber >= 3:
                bonus += 5

        score = max(0, min(100, 100 - penalty + bonus))

        if score >= 80:
            rating = "Excellent"
        elif score >= 60:
            rating = "Good"
        elif score >= 40:
            rating = "Moderate"
        else:
            rating = "Poor"

        return {
            "product_id": product_id,
            "product_name": product["product_name"],
            "nutrition_score": score,
            "rating": rating,
            "calculated_per": "100g",
            "penalty_points": penalty,
            "bonus_points": bonus
        }

    finally:
        conn.close()

# --------------------------------
# 5. PRODUCT COMPARISON
# --------------------------------

@app.get("/products/compare")
def compare_products(
    product_id_1: int = Query(..., gt=0),
    product_id_2: int = Query(..., gt=0)
):

    if product_id_1 == product_id_2:
        raise HTTPException(
            status_code=400,
            detail="Please select two different products"
        )

    conn = get_connection()

    try:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    product_id,
                    product_name,
                    brand_name,
                    serving_size_g,
                    calories_kcal,
                    carbohydrates_g,
                    proteins_g,
                    total_fat_g,
                    saturated_fat_g,
                    sugar_g,
                    sodium_mg,
                    dietary_fiber_g
                FROM products
                WHERE product_id IN (%s, %s)
                """,
                (product_id_1, product_id_2)
            )

            products = cursor.fetchall()

        product_map = {
            p["product_id"]: p for p in products
        }

        if product_id_1 not in product_map or product_id_2 not in product_map:
            raise HTTPException(
                status_code=404,
                detail="One or both products not found"
            )

        return {
            "product_1": product_map[product_id_1],
            "product_2": product_map[product_id_2]
        }

    finally:
        conn.close()



# --------------------------------
# 7. SMART RECOMMENDATIONS WITH EXPLANATIONS
# --------------------------------

@app.get("/products/{product_id}/recommendations")
def recommend_products(
    product_id: int,
    limit: int = Query(5, ge=1, le=20)
):
    conn = get_connection()

    try:
        with conn.cursor() as cursor:

            # Fetch selected product
            cursor.execute(
                """
                SELECT product_id, product_name, brand_name,
                       category, sub_category, serving_size_g,
                       calories_kcal, sugar_g, saturated_fat_g,
                       sodium_mg, proteins_g, dietary_fiber_g
                FROM products
                WHERE product_id = %s
                """,
                (product_id,)
            )

            selected = cursor.fetchone()

            if not selected:
                raise HTTPException(
                    status_code=404,
                    detail="Product not found"
                )

            if not selected["category"] or not selected["sub_category"]:
                return {
                    "message": "Product category information is incomplete.",
                    "recommendations": []
                }

            # Fetch similar products from different brands
            cursor.execute(
                """
                SELECT product_id, product_name, brand_name,
                       serving_size_g, calories_kcal, sugar_g,
                       saturated_fat_g, sodium_mg, proteins_g,
                       dietary_fiber_g
                FROM products
                WHERE UPPER(TRIM(category)) = UPPER(TRIM(%s))
                  AND UPPER(TRIM(sub_category)) = UPPER(TRIM(%s))
                  AND product_id != %s
                  AND brand_name IS NOT NULL
                  AND UPPER(TRIM(brand_name)) != UPPER(TRIM(%s))
                """,
                (
                    selected["category"],
                    selected["sub_category"],
                    product_id,
                    selected["brand_name"] or ""
                )
            )

            candidates = cursor.fetchall()

    finally:
        conn.close()

    # Identify chocolate type
    def get_product_type(name):
        name = (name or "").lower()

        if "white chocolate" in name or "milkybar" in name:
            return "WHITE CHOCOLATE"

        if any(word in name for word in [
            "sugar free", "sugar-free", "keto"
        ]):
            return "SUGAR-FREE CHOCOLATE"

        if "dark" in name:
            return "DARK CHOCOLATE"

        if any(word in name for word in [
            "dairy milk", "milk chocolate",
            "smooth milk", "creamy milk"
        ]):
            return "MILK CHOCOLATE"

        return "OTHER CHOCOLATE"

    selected_type = None

    if selected["category"].strip().upper() == "CHOCOLATE":
        selected_type = get_product_type(selected["product_name"])

    # Convert nutrition values to per 100g
    def get_nutrients(product):
        serving = product["serving_size_g"]

        if serving is None or float(serving) <= 0:
            return None

        def convert(value):
            if value is None:
                return None
            return round(float(value) * 100 / float(serving), 2)

        return {
            "calories": convert(product["calories_kcal"]),
            "sugar": convert(product["sugar_g"]),
            "saturated_fat": convert(product["saturated_fat_g"]),
            "sodium": convert(product["sodium_mg"]),
            "protein": convert(product["proteins_g"]),
            "fiber": convert(product["dietary_fiber_g"])
        }

    # NutriScan project-specific scoring formula
    def calculate_score(nutrients):
        if nutrients is None:
            return None

        calories = nutrients["calories"]
        sugar = nutrients["sugar"]
        sat_fat = nutrients["saturated_fat"]
        sodium = nutrients["sodium"]
        protein = nutrients["protein"]
        fiber = nutrients["fiber"]

        if any(v is None for v in [
            calories, sugar, sat_fat, sodium
        ]):
            return None

        penalty = 0

        if calories > 400:
            penalty += 20
        elif calories > 300:
            penalty += 15
        elif calories > 200:
            penalty += 10
        elif calories > 100:
            penalty += 5

        if sugar > 22.5:
            penalty += 20
        elif sugar > 15:
            penalty += 15
        elif sugar > 5:
            penalty += 10
        elif sugar > 1:
            penalty += 5

        if sat_fat > 5:
            penalty += 15
        elif sat_fat > 2:
            penalty += 10
        elif sat_fat > 1:
            penalty += 5

        if sodium > 600:
            penalty += 15
        elif sodium > 400:
            penalty += 10
        elif sodium > 120:
            penalty += 5

        bonus = 0

        if protein is not None:
            if protein >= 10:
                bonus += 10
            elif protein >= 5:
                bonus += 5

        if fiber is not None:
            if fiber >= 6:
                bonus += 10
            elif fiber >= 3:
                bonus += 5

        return max(0, min(100, 100 - penalty + bonus))

    # Calculate selected product score
    selected_nutrients = get_nutrients(selected)
    selected_score = calculate_score(selected_nutrients)

    if selected_score is None:
        return {
            "selected_product": selected["product_name"],
            "message": "Insufficient nutrition data to recommend alternatives.",
            "recommendations": []
        }

    nutrient_labels = {
        "calories": ("Calories", "kcal"),
        "sugar": ("Sugar", "g"),
        "saturated_fat": ("Saturated fat", "g"),
        "sodium": ("Sodium", "mg"),
        "protein": ("Protein", "g"),
        "fiber": ("Dietary fiber", "g")
    }

    recommendations = []

    # Evaluate similar products
    for candidate in candidates:

        # Match chocolate type
        if selected_type:
            candidate_type = get_product_type(
                candidate["product_name"]
            )

            if candidate_type != selected_type:
                continue

        candidate_nutrients = get_nutrients(candidate)
        candidate_score = calculate_score(candidate_nutrients)

        if candidate_score is None or candidate_score <= selected_score:
            continue

        explanations = []
        comparisons = []

        for key, (label, unit) in nutrient_labels.items():

            selected_value = selected_nutrients[key]
            candidate_value = candidate_nutrients[key]

            if selected_value is None or candidate_value is None:
                continue

            difference = round(
                selected_value - candidate_value, 2
            )

            comparisons.append({
                "nutrient": label,
                "selected_product_value": selected_value,
                "recommended_product_value": candidate_value,
                "unit": unit
            })

            # Lower values for these nutrients
            if key in [
                "calories", "sugar", "saturated_fat", "sodium"
            ] and difference > 0.01:

                explanations.append(
                    f"{label} is {difference} {unit} lower"
                )

            # Higher values for these nutrients
            elif key in ["protein", "fiber"] and difference < -0.01:

                explanations.append(
                    f"{label} is {abs(difference)} {unit} higher"
                )

        if not explanations:
            explanations.append(
                "The higher score comes from the project's scoring "
                "formula; no clear individual nutrient advantage "
                "was identified."
            )

        recommendations.append({
            "product_id": candidate["product_id"],
            "product_name": candidate["product_name"],
            "brand_name": candidate["brand_name"],
            "product_type": selected_type,
            "nutrition_score": candidate_score,
            "selected_product_score": selected_score,
            "score_difference": candidate_score - selected_score,
            "why_recommended": explanations,
            "nutrient_comparison_per_100g": comparisons
        })

    # Highest score first
    recommendations.sort(
        key=lambda item: item["nutrition_score"],
        reverse=True
    )

    recommendations = recommendations[:limit]

    return {
        "selected_product": {
            "product_id": product_id,
            "product_name": selected["product_name"],
            "brand_name": selected["brand_name"],
            "nutrition_score": selected_score
        },
        "product_type": selected_type,
        "category": selected["category"],
        "sub_category": selected["sub_category"],
        "recommendations_found": len(recommendations),
        "message": (
            "Similar products with higher nutrition scores found."
            if recommendations
            else "No higher-scoring similar product from another brand was found."
        ),
        "recommendations": recommendations,
        "calculated_per": "100g",
        "note": (
            "Project-specific nutrition indicator, "
            "not an official medical or health rating."
        )
    }
