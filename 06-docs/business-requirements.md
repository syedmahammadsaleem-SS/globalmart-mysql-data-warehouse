# GlobalMart Data Warehouse - Business Requirements Document

## Project Overview
**Name:** GlobalMart Analytics Data Warehouse  
**Objective:** Transform raw retail transaction data into actionable business intelligence  
**Timeline:** 4 weeks  
**Stakeholders:** CEO, Sales Director, Marketing Manager, Operations Team

## Business Problem
GlobalMart (fictional Fortune 500 retailer) has years of sales data but:
- No structured way to analyze performance
- Revenue is flat while costs are rising
- Competitors are using data analytics to gain market share
- Leadership needs data-driven decisions, not gut feelings

## Key Business Questions
1. **Product Performance:** Which products are profitable vs. loss-making?
2. **Customer Segmentation:** Who are our most valuable customers?
3. **Regional Analysis:** Which regions are underperforming?
4. **Seasonal Trends:** When should we increase inventory?
5. **Shipping Optimization:** How can we reduce delivery costs?

## Success Criteria
- [x] Star Schema database implemented
- [x] 30+ analytical queries built
- [x] RFM customer segmentation completed
- [x] Automated reporting via views and procedures
- [x] Performance optimized with indexes

## Data Sources
- Primary: Superstore dataset (51,290 transactions, 2011-2014)
- Columns: Category, City, Country, Customer, Discount, Market, Order Date, Product, Profit, Quantity, Region, Sales, Segment, Ship Date, Ship Mode, Shipping Cost, State, Sub-Category

## Scope
**In Scope:** Sales analysis, customer segmentation, product profitability, geographic performance, shipping efficiency  
**Out of Scope:** Real-time data, predictive modeling, external data integration