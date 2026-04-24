# ecommerce-customer-segmentation-dashboard
This project focuses on analyzing customer behavior using the RFM (Recency, Frequency, Monetary) model to segment customers and derive actionable business insights. The goal is to identify high-value customers, understand purchasing patterns, and detect potential churn risks.

E-Commerce Customer Segmentation Dashboard
🚀 Overview

This project performs an end-to-end customer analysis using the RFM (Recency, Frequency, Monetary) model to segment customers and uncover actionable business insights. The goal is to identify high-value customers, understand behavior patterns, and detect churn risks using data-driven techniques.

🎯 Business Problem

E-commerce businesses often lack visibility into:

Who their most valuable customers are
Which customers are likely to churn
How customer behavior impacts revenue

This project solves these problems by building a structured segmentation model and an interactive dashboard.

🛠️ Tech Stack
SQL – Data cleaning, transformation, RFM computation
Power BI – Dashboard development and visualization
DAX – KPI calculations and measures
📂 Dataset

The dataset consists of transactional e-commerce data including:

Customer ID
Order details
Purchase dates
Revenue values
⚙️ Project Workflow
1. Data Cleaning (SQL)
Removed duplicates and null values
Handled inconsistent data
Validated data types
2. RFM Analysis
Recency → Days since last purchase
Frequency → Number of transactions
Monetary → Total spending

Customers were scored and segmented based on these metrics.

3. Customer Segmentation

Customers were grouped into:

Champions
Loyal Customers
Potential Loyalists
At Risk
Hibernating
Others
4. Dashboard Development (Power BI)

Built an interactive dashboard including:

KPI Cards (Customers, Revenue, Avg Revenue, Frequency)
Donut Chart (Customer Distribution)
Bar Chart (Revenue by Segment)
Recency vs Frequency Analysis
Customer Value Scatter Plot
Interactive Slicers

💡 Key Insights
Champions drive the majority of revenue
Loyal Customers provide consistent repeat business
At Risk and Hibernating customers indicate churn risk
Potential Loyalists offer strong growth opportunities
Higher purchase frequency leads to higher revenue
