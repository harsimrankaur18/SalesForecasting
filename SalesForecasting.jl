### A Pluto.jl notebook ###
# v0.12.21

using Markdown
using InteractiveUtils

# ╔═╡ 45267810-90ed-11eb-3e0a-41bcbaa89535
using CSV, DataFrames, Dates, StatsPlots, Statistics, StatsBase, BetaML.Clustering, Markdown,TimeSeries

# ╔═╡ 806147c0-90ed-11eb-1329-93d6df530982
md"# _Sales Forecasting_"

# ╔═╡ c0fef57e-9114-11eb-2331-6564e757725a
Data = CSV.read("D:\\Jobs\\Liquid-Analytics\\Project\\OnlineRetail.csv",DataFrame)

# ╔═╡ 36ac74a0-90ee-11eb-10ed-11a038d49509
md" ### Data Cleaning"

# ╔═╡ bd134e20-90ed-11eb-1c06-5d1d492c8e80
# the size
size(Data)

# ╔═╡ ddc5f8c2-90ed-11eb-18f6-d1b30bfe23cc
# the attribute names
names(Data)

# ╔═╡ f028b2a0-90ed-11eb-13c6-a37325914a0e
# Brief description about the data
describe(Data)

# ╔═╡ f3e21120-90ed-11eb-15ce-1fce0fcdcdab
md"""
*  The data has 8 attributes.InvoiceNo, Description, StockCode, InvoiceDate, Country are of String type. Quantity and UnitPrice are Integer type values.
*  A peculiar thing to note is that Quantity has negative values. These -ve values corresponds to the Canceled order which are uniquely Identified by their InvoiceNo begining with C as shown below.
"""	

# ╔═╡ ff1cf9b0-90ed-11eb-3dc0-5d52f33bca3f
# Cancelled Orders
first(filter(row -> row[:Quantity] < 0, Data),5)

# ╔═╡ 40bbae70-90ee-11eb-0bda-35dfd25583a1
md"#### Identify null values"

# ╔═╡ 4e8f1c30-90ee-11eb-2ab1-7fc7284ebf4e
mapcols(x -> count(ismissing, x), Data)

# ╔═╡ 5dd4425e-90ee-11eb-080f-01eea645d6fb
md"##### Remove missing data

* From the CustomerID column, nearly 25% data entries are missing. Therefore, almost 25% of invoices are not assigned to any customer. 
* These invoices cannot be mapped to any random customers without of lack of knowledge. Therefore, these entries needs to be removed from the dataset."

# ╔═╡ 4d0b50a0-9115-11eb-2850-1f88abf0a1b3
begin
	CleanData = dropmissing(Data, :CustomerID)
	mapcols(x -> count(ismissing, x), CleanData)
end

# ╔═╡ 8b38be20-90ee-11eb-0385-0dd776d887a3
md"#### Identify duplicate entries"

# ╔═╡ 8086b4a0-90ee-11eb-008f-17a597bdcbf6
count(nonunique(CleanData))

# ╔═╡ 46cbee12-9116-11eb-05a0-2b097fb1643a
begin
	# Remove duplicate values from data
	unique!(CleanData) 
	count(nonunique(CleanData))
end

# ╔═╡ 68089060-90ee-11eb-1ddb-014fadee0cbb
md" ####  Removing entries with -ve Quantity values"

# ╔═╡ 596aa6b0-90ee-11eb-2f57-135ca7604053
begin
	Clean_Data=filter(row -> row[:Quantity] > 1, CleanData)
	describe(Clean_Data)
end

# ╔═╡ d7be9620-90ee-11eb-254e-6d9f06fdfd07
md"#### Changing date from string to dateTime in Julia"

# ╔═╡ e2b1c74e-90ee-11eb-1010-736bb1bb04d7
begin
	DATEFORMAT = DateFormat("dd-mm-yyyy HH:MM")
	Clean_Data.InvoiceDate = Date.(Clean_Data.InvoiceDate,  DATEFORMAT)
	describe(Clean_Data)
end

# ╔═╡ ee40ea60-90ee-11eb-3a70-d1cd03d079d2
md"#### Adding a column TotalAmount to store the total money spent by each transaction"

# ╔═╡ f92a0970-90ee-11eb-076b-c1868de06a17
begin
	Clean_Data.TotalAmount = Clean_Data.Quantity .* Clean_Data.UnitPrice
	first(Clean_Data,5)
end

# ╔═╡ 081b6a50-90ef-11eb-046b-0be9ec300873
md"### Exploratory Data Analysis

##### Total number of customers, products and transactions in the dataset ?
"

# ╔═╡ 13b27ca0-90ef-11eb-0536-db202e007e7f
DataFrame(Customers = length(unique(Clean_Data[!,"CustomerID"])) , Products = length(unique(Clean_Data[!,"StockCode"])),Transactions= length(unique(Clean_Data[!,"InvoiceNo"]))) 

# ╔═╡ 1b565bc0-90ef-11eb-15fd-8324221f5738
md"* The dataset contain the recods of 4328 customers who bought 3572 different items.
* There are $\sim$18,000 transactions which are carried out.

##### Number of products purchased in every transaction"

# ╔═╡ 9d6e5810-90ef-11eb-3239-d73d8db06bbb
first(sort(combine(groupby(Clean_Data, [:CustomerID, :InvoiceNo]), nrow => :ProductsPerTransaction),(:CustomerID)),10)

# ╔═╡ a61a0a3e-90ef-11eb-2ef9-431e05662248
md"* There are some users who bought only comes one time on the E-commerce platform and purchased one   
  item. The example of this kind of user is customerID 12346.  

* There are some users who frequently buy large number of items per order. The example of this kind of 
  user is customerID 12347.  "

# ╔═╡ ffcec0e0-9116-11eb-0484-af1fcbc8e76c
md"##### Number of transactions made by each customer"

# ╔═╡ 0ea790b2-9117-11eb-1ddb-c1c0010b283a
begin
	
	# transactionsPerCustomer=groupby(data,[:CustomerID,:Country])
	# # groupby(data,[:CustomerID,:Country,:InvoiceNo])
	transactionsPerCustomer = combine(groupby(Clean_Data, [:CustomerID,:Country]), :InvoiceNo=>length∘unique)
	first(DataFrames.rename!(transactionsPerCustomer, :InvoiceNo_length_unique => :Transactions),10)
end

# ╔═╡ 1dcd4800-9117-11eb-257d-416146d063a2
# Top 5 customers
first(sort(transactionsPerCustomer,(:Transactions),rev=true),5)

# ╔═╡ b246098e-90ef-11eb-0994-894d1b4a7cae
md"* The table above hows that the maximum number of transactions(invoices),197, were placed by the customer 14911 in EIRE. 
* Among our top 5 customers, United Kingdom customers secured the last 4 positions indicating that, it can be a potential market for high growth and profit. Therefore, investing more in UK would be beneficial."

# ╔═╡ 363b8dbe-9117-11eb-1987-89022d783065
md"##### Money spent by each customers"

# ╔═╡ 3ee67ca0-9117-11eb-2781-1b658939785e
begin
	moneySpent = combine(groupby(Clean_Data,[:CustomerID,:Country]),:TotalAmount)
#Top 5
first(sort(moneySpent,(:TotalAmount),rev=true),5)
end

# ╔═╡ b9dacd80-90ef-11eb-3d35-e791ced55e25
md"* The table depicts the total amount invested by each customer along with its country. For instance, CustomerID 16446 spent the most amount among the rest.
* Moreover, UK customers were among the top 5 who spent the most amount. "

# ╔═╡ 609d02b0-9117-11eb-3066-e1cd5836c250
md"##### Number of transactions per Month"

# ╔═╡ 726f6370-9117-11eb-08d1-2dd916b0287d
begin
	Clean_Data[!, :month] = yearmonth.(Clean_Data[!, :InvoiceDate])
transactionsPerMonth = combine(groupby(Clean_Data, :month),nrow)
transactionsPerMonth[!, :month]=map(x->string(x), eachrow(transactionsPerMonth.month))
bar(transactionsPerMonth.month,
    transactionsPerMonth.nrow,
    title = "Transactions Per Month",
    xticks = :all,
		label = "Transactions",
    xrotation = 45,
    size = [600, 400])
end 

# ╔═╡ cdea9b20-90ef-11eb-1151-a7c4db1b459c
md"* According to the graph above, most transactions were in November,2011 in a time frame of 11 months.
* Unfortunately we only have 9 days of data for December, 2011. But we hope for a monotonic increase.
* The boom in sales from September, 2011 to November 2011 can be owed to the Holiday season."

# ╔═╡ d578f670-90ef-11eb-286e-5337a8c48c0b
md"##### Number of transactions per Day"

# ╔═╡ d539a380-90ef-11eb-2a42-5939378cbb45
begin
	Clean_Data[!, :day] = dayname.(Clean_Data[!, :InvoiceDate])
	transactionsPerDay = combine(groupby(Clean_Data, :day),nrow)
	bar(transactionsPerDay.day,
		transactionsPerDay.nrow,
		title = "Transactions Per Day",
		xticks = :all,
		label="Transactions",
		xrotation = 45,
		size = [600, 400])
end

# ╔═╡ d509b9e0-90ef-11eb-15bf-411cd693c762
md"* The above bar graph depits the cummulative transcations per week throughout the time frame(Dec,2010 to Dec, 2011).
* According to the bar graph above, the most and the least transcations made was on Thursdays and Sundays respectively.

##### Unit Price Description"

# ╔═╡ d4fe8f20-9117-11eb-0602-d7f1332241fc
# Unit Price
describe(Clean_Data.UnitPrice)

# ╔═╡ d4d4ee40-90ef-11eb-3ba5-9fbc8d9a8ce0
md"We see that there are unit price = 0 (FREE items)

There are some free items given to customers from time to time."

# ╔═╡ ea8b5fd0-9117-11eb-0e41-b13eebc06fc3
begin
	# Distribution of Unit Price
bp1 = boxplot(Clean_Data.UnitPrice,label="Unit Price")
StatsPlots.plot(bp1)
end

# ╔═╡ d48bd74e-90ef-11eb-22a8-ffc32e4dcba6
md"* The box plot above shows the distribution of the Unit Price. It indicates that 75\% prices of each products are below \$3, i.e. the third Quartile.
* However, there are few products that are prices very high as shown by the Outliers in the plot. The maximum price of a product is \$649.5 . These products may impact the overall sales so these outliers are not removed."

# ╔═╡ 049f6650-9118-11eb-3530-6dad1fe9d50b
data_free = filter(row -> row[:UnitPrice]==0 , Clean_Data)

# ╔═╡ 02e11bb0-90f0-11eb-2e2c-834b5b10e368
begin
	data_free[!, :month] = yearmonth.(data_free[!, :InvoiceDate])
freeOrder = combine(groupby(data_free, :month),nrow)
freeOrder[!, :month]=map(x->string(x), eachrow(freeOrder.month))
bar(freeOrder.month,
    freeOrder.nrow,
    title = "Free Products per Month",
    xticks = :all,
    xrotation = 45,
		label="Free Products",
    size = [600, 400])
end

# ╔═╡ 02a76e10-90f0-11eb-1735-7ff16283b21c
md"* On average, the company gave out 2 FREE products to customers each month except in June and September in 2011
* Because of the Thanksgiving in August and, the holiday season in November, more and more products were given free
* Free products given to customers in November were almost 3 folds to the average free products given during the rest of the time frame

##### Products Sold per Country"

# ╔═╡ 49ebb9c0-9118-11eb-2125-c1b33751cf58
# Unique countries in the dataset
length(unique(Clean_Data[!,"Country"]))

# ╔═╡ 376a5450-9118-11eb-3b59-9547a3328f8b
begin
orderPerCountry =   combine(groupby(Clean_Data, :Country), nrow)
orderPerCountry= sort(orderPerCountry,:nrow,rev=true)
bar(orderPerCountry.Country,
    orderPerCountry.nrow,
    title = "Products Sold Per Country",
    xticks = :all,
	label = "Products sold",
    xrotation = 45,
    size = [600, 400])
end

# ╔═╡ c5fb1060-9118-11eb-2fcf-29c0465ec669
begin
	delete!(orderPerCountry, 1)

bar(orderPerCountry.Country,
    orderPerCountry.nrow,
    title = "Products Sold Per Country Excluding UK",
    xticks = :all,
	label = "Products sold",
    xrotation = 45,
    size = [600, 400])
end

# ╔═╡ 02745020-90f0-11eb-048b-4530bec7fe06
md"* Maximum sales occured in UK followed by France , EIRE and Spain. 
* Therefore, investing the UK will surely lead to higher profits.

##### Money Spent by Each Country"

# ╔═╡ 5af5cbfe-9119-11eb-3c9e-4164753257e4
begin
	moneyPerCount = sort(combine(groupby(Clean_Data, [:Country]), :TotalAmount => sum),:TotalAmount_sum,rev=true)
bar(moneyPerCount.Country,
    moneyPerCount.TotalAmount_sum,
    title = "MoneySpent Per Country",
    xticks = :all,
		label="Money Spent",
    xrotation = 45,
    size = [600, 400])

end


# ╔═╡ 7e2d25b0-9119-11eb-2a89-91009abf55da
begin
	delete!(moneyPerCount, 1)
bar(moneyPerCount.Country,
    moneyPerCount.TotalAmount_sum,
    title = "MoneySpent Per Country Excluding UK",
    xticks = :all,
		label="Money Spent",
    xrotation = 45,
    size = [600, 400])
end

# ╔═╡ 8e9966c0-9119-11eb-0e7d-57c883ed2c2c
md"
* UK ranked top among the other countries in terms of money spent.
* This trend seems to continue in all European countries as depicted by the second graph. 
* Saudi Arabia spent the least money and therefore, we should re-consider the idea of investing there."

# ╔═╡ 96cfe8f0-9119-11eb-2d96-53f0322a5529
md"
#### Customer Segmentation

RFM Technique:
* R (Recency) : Number of days since last purchase
* F (Frequency) : Number of transactions
* M (Monetary) : Total amount of transactions (revenue contributed)"

# ╔═╡ 9fa82960-9119-11eb-2595-f1b781f063f9
begin
	# The dataframe contains the amount spent by a each customer in each transaction(invoice)
totalOrder = combine(groupby(Clean_Data,[:InvoiceNo,:CustomerID, :InvoiceDate]),:TotalAmount => sum)
# Reference Date :
REFERENCE_DATE, _ = findmax(Clean_Data.InvoiceDate)
println("Reference Data : " ,REFERENCE_DATE)
first(sort(totalOrder,:CustomerID),6)
end

# ╔═╡ c7b1f2b0-9119-11eb-1d93-59cf7dbc17af
begin
# Recency
totalOrder.Recency = Dates.value.(REFERENCE_DATE .- totalOrder.InvoiceDate)
sort(totalOrder,:CustomerID)
customer = combine(groupby(totalOrder,[:CustomerID]),:Recency => minimum)
DataFrames.rename!(customer, :Recency_minimum => :Recency)

# Frequency
customer.Frequency = combine(groupby(totalOrder,[:CustomerID]),nrow => :Frequency).Frequency

# Monetary
customer.Monetary = combine(groupby(totalOrder,[:CustomerID]),:TotalAmount_sum => sum).TotalAmount_sum_sum

# Customer Dataset
first(customer,10)
	
# Analysis of RFM
bp_Recency = boxplot(customer.Recency,label = "Recency",color="green")
bp_Frequency = boxplot(customer.Frequency,label = "Frequency")
bp_Monetary = boxplot(customer.Monetary,label = "Monetary",color="red")
plot(bp_Recency,bp_Frequency,bp_Monetary,layout=(1,3))


end

# ╔═╡ 23a50060-911c-11eb-39fb-95c6504a6aa2
md"* Monetary values contains large number of Outliers that needs to be removed as they will try to skew the dataset leading to improper cluster formation.
* Outliers outside the 1.5* IQR(Inter Quartile Range) range will be removed."

# ╔═╡ 28d74340-911c-11eb-3266-e311a5968283
begin
	# Removing Outliers in Recency values
	quartile1 = quantile!(customer.Recency,0.05)
	quartile3 = quantile!(customer.Recency,0.95)
	IQR = quartile3 - quartile1
	customer_1 = filter(row -> ((row[:Recency] >= quartile1-1.5*IQR)  & (row[:Recency] <= quartile3 + 1.5*IQR)),customer)
	
	# Removing Outliers in Frequency values
	quartile1 = quantile!(customer.Frequency,0.05)
	quartile3 = quantile!(customer.Frequency,0.95)
	IQR = quartile3 - quartile1
	customer_2 = filter(row -> ((row[:Frequency] >= quartile1-1.5*IQR)  & (row[:Frequency] <= quartile3 + 1.5*IQR)),customer_1)
	
	
	# Removing Outliers in Monetary values
	quartile1 = quantile!(customer.Monetary,0.05)
	quartile3 = quantile!(customer.Monetary,0.95)
	IQR = quartile3 - quartile1
	Customer = filter(row -> ((row[:Monetary] >= quartile1-1.5*IQR)  & (row[:Monetary] <= quartile3 + 1.5*IQR)),customer_2)
	
	bp_Recency1 = boxplot(Customer.Recency,label = "Recency",color="green")
	bp_Frequency1 = boxplot(Customer.Frequency,label = "Frequency")
	bp_Monetary1 = boxplot(Customer.Monetary,label = "Monetary",color="red")
	plot(bp_Recency1,bp_Frequency1,bp_Monetary1,layout=(1,3))
end

# ╔═╡ 19a09c00-911c-11eb-3a6b-aba9f647b647
md"#### Feature Scaling

* The customer RFM dataset has different scales for different features. Feature Scaling Algorithms will scale all the features in a fixed range so that no feature can dominate others.
* Standardization technique is used to perform feature scaling on the customer dataset. It is a very effective technique that re-scales a feature value so that it has distribution with 0 mean value and variance equals to 1(Normal Distribution)."

# ╔═╡ 880b8420-911c-11eb-2c72-d5daa9fe9abd
begin
	# rfm = [customer[!,[:Recency,:Frequency,:Monetary]]]
# typeof(rfm)

rfmMatrix = convert(Matrix, Customer[:,2:4])
transformedData = fit(ZScoreTransform, rfmMatrix, dims=1)
X = StatsBase.transform(transformedData, rfmMatrix)
end

# ╔═╡ 9231a150-911c-11eb-210d-a94ee4c4d36b
md"#### Clustering using GMM"

# ╔═╡ 1012c730-911c-11eb-2c9d-19414df31464
begin
	
	lowestBic = Inf
	bicValues = Vector{Float64}()
	n_components_range = collect(2:5)
	cv_types = [FullGaussian,SphericalGaussian,DiagonalGaussian]
	for cv_type in cv_types
		for n_components in n_components_range
			model = gmm(X, n_components,maxIter=10,mixtures=[cv_type() for i in 									1:n_components])
			push!(bicValues,model.BIC)
		end
	end
       
end

# ╔═╡ 88c5e650-91d3-11eb-2f82-b50cbc904345
begin
	xlabel = repeat((2:5), outer = 3)
	gmmTypeLabels = repeat(["Full", "Spherical","Diagonal"], inner = (maximum(n_components_range)-			minimum(n_components_range)+1))
	groupedbar(xlabel, bicValues, group = gmmTypeLabels, ylabel = "BIC values", 
        title = "BIC score per model with kmeans initialization")
end

# ╔═╡ ddf4e210-911b-11eb-1915-d3de77faeb47
md" * The value of k for which there is constant change in the BIC values with an increase in the clusters i.e. the gradient of the BIC values starts to become constant that k is suggested as the optimal value of the number of components of the model.
* The smaller the BIC value the better is the model in predicting the data.
* However, BIC penalizes the models with larger number of clusters to avoid over-fitting. Therefore, amongst the number of clusters: 3,4 & 5 with very low BIC value of GMM with a full covariance matrix as compared to the rest of the models, the best GMM model has 3 clusters.
* Hence, 3 component GMM seems to the best fit with the BIC value of ~19849. 
"

# ╔═╡ e5c7f430-91ef-11eb-3c15-e77ce22ce1ea
customerClusters = gmm(X, 3,maxIter=10,mixtures=[FullGaussian() for i in 1:3],verbosity = HIGH)

# ╔═╡ d9833cc0-91ef-11eb-1a83-ed2779f551cb
clusterProbability = customerClusters.pₙₖ

# ╔═╡ e5b31730-91f0-11eb-23e8-f7ac660a2135
begin
	clusters = [x[2] for x in argmax(clusterProbability, dims=2)]
	Customer.Cluster = vec(clusters)
	first(Customer,10)
end

# ╔═╡ 5c9f4380-925c-11eb-2e44-358ba67073e4
begin
	cluster1Customers = filter(row -> row[:Cluster] == 1 , Customer).CustomerID
		cluster1Customers_sales = sort(filter(row -> row[:CustomerID] ∈ cluster1Customers , totalOrder),:CustomerID)
			cluster1Customers_sales[!, :month] = yearmonth.(cluster1Customers_sales[!, :InvoiceDate])
		cluster1Customers_sales_monthly = combine(groupby(cluster1Customers_sales, :month),:TotalAmount_sum => sum)
		cluster1Customers_sales_monthly=sort(cluster1Customers_sales_monthly,:month)
		DataFrames.rename!(cluster1Customers_sales_monthly, :TotalAmount_sum_sum => :TotalSales)
	
		
		xlabel_cluster1 = ["apr_2011","may_2011","june_2011","july_2011","aug_2011","sept_2011","oct_2011","nov_2011","dec_2011"]
			plot(xlabel_cluster1,cluster1Customers_sales_monthly.TotalSales,xrotation = 45,label="Total Sales",title="Sales per month for Cluster 1 customers")
end

# ╔═╡ 2466d3d0-925b-11eb-135e-e1ae89c2e488
begin
	cluster2Customers = filter(row -> row[:Cluster] == 2 , Customer).CustomerID
	cluster2_customer_sales = sort(filter(row -> row[:CustomerID] ∈ cluster2Customers , totalOrder),:CustomerID)
	cluster2_customer_sales[!, :month] = yearmonth.(cluster2_customer_sales[!, :InvoiceDate])
cluster2_customer_sales_monthly = combine(groupby(cluster2_customer_sales, :month),:TotalAmount_sum => sum)
	cluster2_customer_sales_monthly = sort(cluster2_customer_sales_monthly,:month)
	DataFrames.rename!(cluster2_customer_sales_monthly, :TotalAmount_sum_sum => :TotalSales)
	x_labels =["dec_2010","jan_2011","feb_2011","mar_2011","apr_2011","may_2011","june_2011","july_2011","aug_2011","sept_2011","oct_2011","nov_2011","dec_2011"]
	plot(x_labels,cluster2_customer_sales_monthly.TotalSales,xrotation = 45,label="Total Sales",title="Sales per month for Cluster 2 customers")
end

# ╔═╡ 185edb70-9254-11eb-14ac-09b7cdb71b18
begin
	cluster3Customers = filter(row -> row[:Cluster] == 3 , Customer).CustomerID
	cluster3Customers_sales = sort(filter(row -> row[:CustomerID] ∈ cluster3Customers , totalOrder),:CustomerID)
		cluster3Customers_sales[!, :month] = yearmonth.(cluster3Customers_sales[!, :InvoiceDate])
	cluster3Customers_sales_monthly = combine(groupby(cluster3Customers_sales, :month),:TotalAmount_sum => sum)
	cluster3Customers_sales_monthly=sort(cluster3Customers_sales_monthly,:month)
	DataFrames.rename!(cluster3Customers_sales_monthly, :TotalAmount_sum_sum => :TotalSales)

	
	x_labels_cluster3 =["dec_2010","jan_2011","feb_2011","mar_2011","apr_2011","may_2011","june_2011","july_2011","aug_2011","sept_2011","oct_2011","nov_2011","dec_2011"]
		plot(x_labels_cluster3,cluster3Customers_sales_monthly.TotalSales,xrotation = 45,label="Total Sales",title="Sales per month for Cluster 3 customers")
end

# ╔═╡ 65d73ab0-925d-11eb-1bfa-4dc1ef9dc5f0
md"##### Forecasting Sales for three categories of customers"

# ╔═╡ 859b1880-925d-11eb-1caf-b31510259dc2
begin
	# Cluster 1 Customers
	cluster1_date_data = combine(groupby(cluster1Customers_sales,:InvoiceDate),:TotalAmount_sum=>sum)
	DataFrames.rename!(cluster1_date_data, :TotalAmount_sum_sum => :TotalSales)
	cluster1_date_data = sort(cluster1_date_data,:InvoiceDate)
	cluster1_timeseries = TimeSeries.TimeArray(cluster1_date_data.InvoiceDate,cluster1_date_data.TotalSales)
end

# ╔═╡ 511c6330-9261-11eb-2c9c-61dc3e7f5aec
plot(cluster1_timeseries[:A],label="Sales",title="Time Series: Cluster 1 Customer")

# ╔═╡ 34f19fc0-9263-11eb-1628-f7436a18ecf3


# ╔═╡ Cell order:
# ╟─806147c0-90ed-11eb-1329-93d6df530982
# ╠═45267810-90ed-11eb-3e0a-41bcbaa89535
# ╠═c0fef57e-9114-11eb-2331-6564e757725a
# ╟─36ac74a0-90ee-11eb-10ed-11a038d49509
# ╠═bd134e20-90ed-11eb-1c06-5d1d492c8e80
# ╠═ddc5f8c2-90ed-11eb-18f6-d1b30bfe23cc
# ╠═f028b2a0-90ed-11eb-13c6-a37325914a0e
# ╟─f3e21120-90ed-11eb-15ce-1fce0fcdcdab
# ╠═ff1cf9b0-90ed-11eb-3dc0-5d52f33bca3f
# ╟─40bbae70-90ee-11eb-0bda-35dfd25583a1
# ╠═4e8f1c30-90ee-11eb-2ab1-7fc7284ebf4e
# ╟─5dd4425e-90ee-11eb-080f-01eea645d6fb
# ╠═4d0b50a0-9115-11eb-2850-1f88abf0a1b3
# ╟─8b38be20-90ee-11eb-0385-0dd776d887a3
# ╠═8086b4a0-90ee-11eb-008f-17a597bdcbf6
# ╠═46cbee12-9116-11eb-05a0-2b097fb1643a
# ╟─68089060-90ee-11eb-1ddb-014fadee0cbb
# ╠═596aa6b0-90ee-11eb-2f57-135ca7604053
# ╟─d7be9620-90ee-11eb-254e-6d9f06fdfd07
# ╠═e2b1c74e-90ee-11eb-1010-736bb1bb04d7
# ╟─ee40ea60-90ee-11eb-3a70-d1cd03d079d2
# ╠═f92a0970-90ee-11eb-076b-c1868de06a17
# ╟─081b6a50-90ef-11eb-046b-0be9ec300873
# ╠═13b27ca0-90ef-11eb-0536-db202e007e7f
# ╟─1b565bc0-90ef-11eb-15fd-8324221f5738
# ╠═9d6e5810-90ef-11eb-3239-d73d8db06bbb
# ╟─a61a0a3e-90ef-11eb-2ef9-431e05662248
# ╟─ffcec0e0-9116-11eb-0484-af1fcbc8e76c
# ╠═0ea790b2-9117-11eb-1ddb-c1c0010b283a
# ╠═1dcd4800-9117-11eb-257d-416146d063a2
# ╟─b246098e-90ef-11eb-0994-894d1b4a7cae
# ╟─363b8dbe-9117-11eb-1987-89022d783065
# ╠═3ee67ca0-9117-11eb-2781-1b658939785e
# ╟─b9dacd80-90ef-11eb-3d35-e791ced55e25
# ╟─609d02b0-9117-11eb-3066-e1cd5836c250
# ╠═726f6370-9117-11eb-08d1-2dd916b0287d
# ╟─cdea9b20-90ef-11eb-1151-a7c4db1b459c
# ╟─d578f670-90ef-11eb-286e-5337a8c48c0b
# ╠═d539a380-90ef-11eb-2a42-5939378cbb45
# ╟─d509b9e0-90ef-11eb-15bf-411cd693c762
# ╠═d4fe8f20-9117-11eb-0602-d7f1332241fc
# ╟─d4d4ee40-90ef-11eb-3ba5-9fbc8d9a8ce0
# ╠═ea8b5fd0-9117-11eb-0e41-b13eebc06fc3
# ╟─d48bd74e-90ef-11eb-22a8-ffc32e4dcba6
# ╠═049f6650-9118-11eb-3530-6dad1fe9d50b
# ╠═02e11bb0-90f0-11eb-2e2c-834b5b10e368
# ╟─02a76e10-90f0-11eb-1735-7ff16283b21c
# ╠═49ebb9c0-9118-11eb-2125-c1b33751cf58
# ╠═376a5450-9118-11eb-3b59-9547a3328f8b
# ╠═c5fb1060-9118-11eb-2fcf-29c0465ec669
# ╟─02745020-90f0-11eb-048b-4530bec7fe06
# ╠═5af5cbfe-9119-11eb-3c9e-4164753257e4
# ╠═7e2d25b0-9119-11eb-2a89-91009abf55da
# ╟─8e9966c0-9119-11eb-0e7d-57c883ed2c2c
# ╟─96cfe8f0-9119-11eb-2d96-53f0322a5529
# ╠═9fa82960-9119-11eb-2595-f1b781f063f9
# ╠═c7b1f2b0-9119-11eb-1d93-59cf7dbc17af
# ╟─23a50060-911c-11eb-39fb-95c6504a6aa2
# ╠═28d74340-911c-11eb-3266-e311a5968283
# ╟─19a09c00-911c-11eb-3a6b-aba9f647b647
# ╠═880b8420-911c-11eb-2c72-d5daa9fe9abd
# ╟─9231a150-911c-11eb-210d-a94ee4c4d36b
# ╠═1012c730-911c-11eb-2c9d-19414df31464
# ╠═88c5e650-91d3-11eb-2f82-b50cbc904345
# ╟─ddf4e210-911b-11eb-1915-d3de77faeb47
# ╠═e5c7f430-91ef-11eb-3c15-e77ce22ce1ea
# ╠═d9833cc0-91ef-11eb-1a83-ed2779f551cb
# ╠═e5b31730-91f0-11eb-23e8-f7ac660a2135
# ╠═5c9f4380-925c-11eb-2e44-358ba67073e4
# ╠═2466d3d0-925b-11eb-135e-e1ae89c2e488
# ╠═185edb70-9254-11eb-14ac-09b7cdb71b18
# ╟─65d73ab0-925d-11eb-1bfa-4dc1ef9dc5f0
# ╠═859b1880-925d-11eb-1caf-b31510259dc2
# ╠═511c6330-9261-11eb-2c9c-61dc3e7f5aec
# ╠═34f19fc0-9263-11eb-1628-f7436a18ecf3
