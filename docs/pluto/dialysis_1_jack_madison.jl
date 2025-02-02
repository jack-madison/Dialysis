### A Pluto.jl notebook ###
# v0.19.19

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 5c1aeb4f-fef2-41d0-813f-eb78728ea83b
begin 
	# the Dialysis.jl package is not in the official Julia registry, so we need to tell Julia / Pluto where to find it
	import Pkg
	Pkg.Registry.add(Pkg.Registry.RegistrySpec(url="https://github.com/schrimpf/juliaregistry.git"))
end

# ╔═╡ c6f8ecfe-0e81-45a9-b7e6-a9ff629b549b
using PlutoUI

# ╔═╡ a80227f8-5f77-11eb-1211-95dd2c151877
using DataFrames, # package for storing and interacting with datasets
	Dates, Dialysis

# ╔═╡ 2dda9576-5f90-11eb-29eb-91dec5be5175
using Statistics, StatsBase # for mean, var, etc

# ╔═╡ b443a46e-5fa3-11eb-3e71-dfd0683dc6e9
begin
  using StatsPlots , Plots, VegaLite
  Plots.gr(fmt="png")
end

# ╔═╡ d5554696-5f6f-11eb-057f-a79641cf483a
md"""

# Reproducing Grieco & McDevitt (2017)

Paul Schrimpf

[UBC ECON567](https://faculty.arts.ubc.ca/pschrimpf/565/565.html)

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-sa/4.0/)
[Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/)
"""

# ╔═╡ ad1cc4c6-5f72-11eb-35d5-53ff88f1f041
md"""

# Getting Started

## Installing Julia and Pluto

You can install Julia and Pluto on your own computer. To do so, first
download and install Julia from
[https://julialang.org/](https://julialang.org/). I recommend the
choosing the current stable release.

After installing, open Julia. This will give a Julia command
prompt. Enter `]` to switch to package manager mode. The command
prompt should change from a green `julia>` to a blue `(@v1.7) pkg>`. In
package mode, type `add Pluto` and press enter. This installs the
[Pluto.jl package](https://github.com/fonsp/Pluto.jl) and its
dependencies. It will take a few minutes. When finished, type `Ctrl+c`
to exit package mode. Now at the green `julia>` prompt, enter

```julia
using Pluto
Pluto.run()
```

This will open the Pluto interface in your browser. If you close Julia
and want to start Pluto again, you only need to repeat this last step.

Download the notebook file from [github](https://raw.githubusercontent.com/UBCECON567/Dialysis/master/docs/pluto/dialysis-1.jl) and open it in Pluto. 

!!! tip 
    Instead of downloading the notebook manually, you can let Julia download when Pluto starts by entering 
    ```julia
    Pluto.run(notebook="https://raw.githubusercontent.com/UBCECON567/Dialysis/master/docs/pluto/dialysis-1.jl")
    ``` 
    instead of `Pluto.run()`. Be sure to save the notebook somewhere on your computer after it opens.
"""



# ╔═╡ 85ab85ff-6986-46e5-b8ba-6c80ccca8a3e
md"""
## Julia Resources

This assignment will try to explain aspects of Julia as
needed. However, if at some point you feel lost, you may want to
consult some of the following resources. Reading the first few
sections of either QuantEcon or Think Julia is recommended.

- [Think Julia](https://benlauwens.github.io/ThinkJulia.jl/latest/book.html#_colophon)
  A detailed introduction to Julia and programming more
  generally. Long, but recommended, especially if you're new to
  programming.

- [QuantEcon with Julia](https://lectures.quantecon.org/jl/)

- From the julia prompt, you can access documentation with
  `?functionname`. Some packages have better documentation than
  others.

- [https://julialang.org/](https://julialang.org/) is the website for
  Julia

- Documentation for core Julia can be found at
  [https://docs.julialang.org/](https://docs.julialang.org/). All
  Julia packages also have a github page. Many of these include
  package specific documentation.

- [Notes on Julia from ECON
  622](https://github.com/ubcecon/ECON622_2020) much of this is part
  of QuantEcon, but not all

- [The Julia Express](https://github.com/bkamins/The-Julia-Express)
  short book with examples of Julia usage

- [discourse.julialang.org](https://discourse.julialang.org/) is a discussion  forum for julia

- [Julia Slack](https://julialang.org/slack/)

!!! tip 
    Pluto has a handful of keyboard shortcuts. You can view them by pressing F1 or Ctrl+?

"""


# ╔═╡ 24722a1a-7213-40ae-9fc8-e9e59924b758
versioninfo()

# ╔═╡ b2c0299f-5711-4071-8c29-b78616e5f874
Pkg.status()

# ╔═╡ 9e653793-a4dc-4843-980b-d8921303422f
PlutoUI.TableOfContents(title="Reproducing Grieco & McDevitt (2017)")

# ╔═╡ 7b4ecdee-5f73-11eb-388c-4d6f9719d79b
md"""

# Part I: Loading and exploring the data


## Packages

Like many programming environments (R, Python, etc), Julia relies on
packages for lots of its functionality. Pluto has [built-in package management](https://github.com/fonsp/Pluto.jl/wiki/%F0%9F%8E%81-Package-management), and Julia automatically downloaded all the packages this notebook uses when you first opened it. 
"""

# ╔═╡ a75918ae-5f73-11eb-3a3e-2f64c0dcc49c
md"""
## Load Data

Now let's get to work. I originally downloaded the data for this
problem set from
[data.cms.gov](https://data.cms.gov/browse?q=dialysis). Here, you will
find zip files for each fiscal year from 2008-2021. As in @grieco2017
the data comes from Dialysis Facility Reports (DFRs) created under
contract to the Centers for Medicare and Medicaid Services
(CMS). However, there are some differences. Most notably, this data
covers 2003-2019, instead of 2004-2008 as in @grieco2017.

The Julia code in
[Dialysis/src/data.jl](https://github.com/UBCECON567/Dialysis/blob/master/src/Dialysis.jl)
downloads and combines the data files. I did my best to include all
the variables (plus more) used by @grieco2017. However, the underlying
data is complicated (there are over 1500 variables each year), so it's
possible I have made mistakes. It might be useful to look at
the documentation included with any of the "Dialysis Facility Report
Data for FY20XX" zip files at [data.cms.gov](https://data.cms.gov/browse?q=dialysis).

The result of the code in `data.jl` is the `dfr.zip` file contained in
the git repository for this assignment. This zip file contains a csv
file with most of the variables used by @grieco2017, as well as some
additional information.
"""

# ╔═╡ b9e1f8de-5f77-11eb-25b8-57e263315ac3
begin
	dialysis, datadic = Dialysis.loadDFR()
	dialysis
end

# ╔═╡ a06995aa-5f78-11eb-3939-f9aca087b12c
md"""
The variable `dialysis` now contains a `DataFrame` with the data. The variable `datadic` is a `Dictionary` with brief descriptions of the columns in `dialysis`.

Use `datadic` as follows.
"""

# ╔═╡ 5b2d6ebe-5f78-11eb-0528-ab36ae696a35
datadic["dis2"]

# ╔═╡ 5ea12c9c-5f79-11eb-34e7-2d7f07854b31
md"""
For more information on any of the variables, look at the documentation included with any of the "Dialysis Facility Report
Data for FY20XX" zip files at [data.cms.gov](https://data.cms.gov/browse?q=dialysis). The FY2008 file might be best, since the `dialysis` dataframe uses the variable names from that year (a handful of variable names change later, but most stay the same).
"""

# ╔═╡ 95ad1f3c-5f79-11eb-36fb-1b384c84317c
md"""
We will begin our analysis with some data cleaning. Then we will create some  exploratory statistics and figures. There are at least two reasons for this. 
First, we want to
check for any anomalies in the data, which may indicate an error in
our code, our understanding of the data, or the data itself. Second,
we should try to see if there are any striking patterns in the data
that deserve extra attention. We can get some information about all
the variables in the data as follows
"""

# ╔═╡ ca038b54-5f79-11eb-0851-9f684e3bb83f
describe(dialysis)

# ╔═╡ cfaabda0-5f79-11eb-17e4-a7cd045681da
md"""

## Data Cleaning

From the above, we can see that the data has some problems. It appears that "." is used to indicate missing. We should replace these with `missing`. Also, the `eltype` of most columns is `String.` We should convert to numeric types where appropriate. 

!!! note "Types"
    Every variable in Julia has a [type](https://docs.julialang.org/en/v1/manual/types/), which determines what information the variable can store. You can check the type of a variable with `typeof(variable)`. The columns of our `dialysis` DataFrame will each be some array-like type that can hold some particular types of elements. For examble, `typeof(dialysis[!,:nursePT])` (or equivalently `typeof(dialysis.nursePT)` should currently be `Array{String, 1}`. This means that right now the nursePT column can only hold strings. Therefore trying to assign an integer to an element of the column like `dialysis[2, :nursePT] = 0` will cause an error. If we want to convert the element type of the column, we have to assign the column to an entirely new array. We will do this below. 

!!! note "Missing"
    [Julia includes a special type and value to represent missing data](https://docs.julialang.org/en/v1/manual/missing/). The element type of arrays that include `missing` will be `Union{Missing, OTHERTYPE}` where `OTHERTYPE` is something like `String` or `Float64`. The `Union` means each element of the array can hold either type `Missing` or `OTHERTYPE`. Some functions will behave reasonably when they encounter `missing` values, but many do not. As a result, we will have to be slightly careful with how we handle `missing` values.

Although not apparent in the `describe(dialysis)` output, it is also worth mentioning the unique format of the data. The data is distributed with one file per fiscal year. Each fiscal year file reports the values of most variables in calendar years 6 to 2 years ago. We need to convert things to have a single calendar year value for each variable.

### Type Conversion

We begin by converting types. We will use [regular expressions](https://docs.julialang.org/en/v1/manual/strings/#Regular-Expressions) to try identify columns whose strings all look like integers or all look like floating point numbers.
Many programming languages have ways to work with regular expressions. It is worth remembering regular expressions are a useful tool for parsing strings, but beyond that do not worry about the dark art of regular expressions too much.
"""

# ╔═╡ c642b578-5f77-11eb-1346-15a35500e61f
"""
    guesstype(x)

Try to guess at appropriate type for x.
"""
function guesstype(x::AbstractArray{T}) where T <:Union{S,Missing} where S <: AbstractString
	# r"" creates a regular expression
	# regular expressions are useful for matching patterns in strings
	# This regular expression matches strings that are either just "." or begin with - or a digit and are followed by 0 or more additional digits
	#
	# all(array) is true if all elements of the array are true
	#
	# skipmissing(x) creates a iterator over the non-missing elements of x (this iterator will behave like an array of the non-missing elements of x)
	if all(occursin.(r"(^\.$)|(^(-|)\d+)$",skipmissing(x)))
		return Int
	elseif all(occursin.(r"(^\.$)|(^(-|\d)\d*(\.|)\d*$)",skipmissing(x)))
		return Float64
	elseif all(occursin.(
				r"(^\.$)|(^\d\d\D{3}\d{4}$|^\d\d/\d\d/\d{4}$)",
				skipmissing(x)))
		return Date
	else
		return S
	end
end

# ╔═╡ 3d6cf930-5f80-11eb-04a1-0f608e26886b
guesstype(x) = eltype(x)

# ╔═╡ c7192aba-5fe8-11eb-1d50-81cb0f959b4a
md"""
!!! info "Broadcasting"
    It is very common to want to apply a function to each element of an array. We call this broadcasting. To broadcast a function, put a `.` between the function name and `(`. Thus, `occursin.(r"(^\.$)|(^(-|)\d+)$",X)`  produces the same result as
    ```julia
    out = Array{Bool, 1}(undef, length(X))
    for i in 1:length(x)
      out[i] = occursin(r"(^\.$)|(^(-|)\d+)$",X[i])
    end    
    ```

"""

# ╔═╡ 600c6368-5f80-11eb-24b1-c35a333d7164
md"""

!!! note "Multiple Dispatch"
    An important Julia feature for organizing code is multiple dispatch. Multiple dispatch refers to having multiple definitions of functions with the same name, and which version of the function gets used is determined by the types of the function arguments. In the second code block above, we defined a generic `guesstype(x)` for any type of argument `x`. In the first code block, we have a more specialized `guesstype(x)` function for `x` that are `AbstractArray` with element type either `String`, `Missing` or `Union{String, Missing}`. When we call `guesstype(whatever)` below, the most specific version of `guesstype` that fits the type of `whatever` will get used.
"""

# ╔═╡ bcaf264a-5f77-11eb-2bf5-1bd3c16dbce6
guesstype(["1", "3.3", "5"]) # this will call the first definition of guesstype since the argument is an Array of String

# ╔═╡ 46da23f6-5f82-11eb-2c42-dbcf1c09192e
guesstype([12.4, -0.8]) # this will call the second definition of guesstype since the argument is an Array of Float64

# ╔═╡ 65d2d0e8-5f85-11eb-2e4b-b3e561a1a63c
md"""
Again using multiple dispatch, we can create a function to convert the types of the columns of the `dialysis` DataFrame.
"""

# ╔═╡ 81b220c8-5f82-11eb-141a-53ed12752330
converttype(x) = x

# ╔═╡ 1f577cac-5feb-11eb-19c7-2ff4856aee9d
md"""
!!! info "Adding Methods to Existing Functions"
    `Base.parse` is a function included in Julia for converting strings to numeric types.
    We want to use parse to convert the types of our DataFrame columns.
    However, for some columns, we want to leave strings as strings, and for others we want to convert strings to dates.
    The builtin parse function only converts strings to numbers.
    However, we can define additional parse methods and use multiple dispatch to handle these cases.
	
	🏴‍☠️ Adding methods for types that we did not create to existing functions is called [type piracy](https://docs.julialang.org/en/v1/manual/style-guide/#Avoid-type-piracy). Type piracy can break code in unexpected ways, so it should be avoided. Instead of definining new methods for `Base.parse`, we create a new function `myparse` and add methods to it.🏴‍☠️

    This approach will make the `converttype` function defined below very short and simple.
"""

# ╔═╡ 3f871682-5f86-11eb-2c50-971aa2d55aec
begin
	myparse(t,x) = Base.parse(t,x)
	# we need a parse that "converts" a string to string
	myparse(::Type{S}, x::S) where S <: AbstractString = x 
	
	# a version of parse that works for the date formats in this data
	myparse(::Type{Dates.Date}, x::AbstractString) = occursin(r"\D{3}",x) ? Date(x, "dduuuyyyyy") : Date(x,"m/d/y")
	myparse
end

# ╔═╡ 34fa745c-5fec-11eb-3c3c-67eba7bffa6e
md"""
!!! info "Ternary Operator"
    In `converttype`, we use the [ternary operator](https://docs.julialang.org/en/v1/base/base/#?:), which is just a concise way to write an if-else statement.
    ```julia
    boolean ? value_if_true : value_if_false
    ```
"""

# ╔═╡ 985c4280-5fec-11eb-362b-21e463e63f8d
md"""
!!! info "Array Comprehension"
    In `converttype`, we use an [array comprehension](https://docs.julialang.org/en/v1/manual/arrays/#man-comprehensions) to create the return value. Comprehensions  are a concise and convenient way to create new arrays from existing ones. 

    [Generator expressions](https://docs.julialang.org/en/v1/manual/arrays/#Generator-Expressions) are a related concept. 
"""

# ╔═╡ 7c756c72-5f83-11eb-28d5-7b5654c51ea3
function converttype(x::AbstractArray{T}) where T <: Union{Missing, AbstractString}
	etype = guesstype(x)
	return([(ismissing(val) || val==".") ? missing : myparse(etype,val)
		for val in x])
end

# ╔═╡ 8c8cab5a-5f85-11eb-1bb0-e506d437545d
md"""
A quick test.
"""

# ╔═╡ 57324928-5f83-11eb-3e9f-4562c8b03cd4
converttype([".","315", "-35.8"])

# ╔═╡ a3452e58-5f85-11eb-18fb-e5f00173defb
clean1 = let
	clean1 = mapcols(converttype, dialysis) # apply converttype to each column of dialysis
	
	# fix the identifier strings. some years they're listed as ="IDNUMBER", others, they're just IDNUMBER
	clean1.provfs = replace.(clean1.provfs, "="=>"")
	clean1.provfs = replace.(clean1.provfs,"\""=>"")
	clean1
end

# ╔═╡ f6620c93-56fd-45b4-9b4e-6cb6ec8736c7
guesstype(dialysis.ptcareFT) <: Union{Missing,AbstractString}

# ╔═╡ bff2e0a8-5f86-11eb-24fd-9504f5c47ffb
describe(clean1)

# ╔═╡ f895392e-5f8b-11eb-1d7a-3f9c6c5ce483
md"""
That looks better.
"""

# ╔═╡ 123a49dc-5f8c-11eb-1c59-c5e5715b819f
md"""
### Reshaping

Now, we will deal with the fiscal year/calendar year issues. As mentioned earlier, most variables that vary over time have their values reported for four previous years in each of the fiscal year data files. Thus, for these variables we will have four reports of what should be the same value. The values may not be the same if there are any data entry errors or similar problems. Let's begin by checking for this.
"""

# ╔═╡ 0b1b8522-5f90-11eb-2f9e-91707f735fe6
let
	# the Statistics.var function will give errors with Strings
	numcols = (Symbol(c) for c in names(clean1) if eltype(clean1[!,c]) <: Union{Missing, Number})
	# replace NaN with missing
	function variance(x)
		v=var(skipmissing(x))
		return(isnan(v) ? missing : v)
	end

	# display summary stats of within provfs and year variances
	describe(
		# compute variance by provfs and year
		combine(groupby(clean1, [:provfs, :year]),
			(numcols) .=> variance)
		)
end

# ╔═╡ 2beddacc-5f93-11eb-35a0-cfee0361b2eb
md"""
The median variance is generally 0---most providers report variables consistently across years. However, there are large outliers. As a simple, but perhaps not best solution, we will use the median across fiscal years of each variable.
"""

# ╔═╡ 468e9380-5f96-11eb-1e57-9bf6b185cbd1
clean2=let
	function combinefiscalyears(x::AbstractArray{T}) where T <: Union{Missing,Number}
		if all(ismissing.(x))
			return(missing)
		else
			v = median(skipmissing(x))
			return(isnan(v) ? missing : v)
		end
	end
	function combinefiscalyears(x)
		# use most common value
		if all(ismissing.(x))
			return(missing)
		else
			return(maximum(countmap(skipmissing(x))).first)
		end
	end
	clean2 = combine(groupby(clean1, [:provfs,:year]),
		names(clean1) .=> combinefiscalyears .=> names(clean1))
	sort!(clean2, [:provfs, :year])
end

# ╔═╡ 2632c508-5f9c-11eb-149b-edb3f5aee983
md"""

### Defining Needed Variables

Now, let's create the variables we will need.

#### Labor

The labor related variables all end in `FT` (for full-time) or `PT` (for part-time). Create labor as a weighted sum of these variables.

"""

# ╔═╡ 62f7ee18-5f9d-11eb-1b6c-4dabc3f9d787
filter(x->occursin.(r"(F|P)T$",x.first), datadic) # list variables ending with PT or FT

# ╔═╡ 656f7c7e-5f9d-11eb-041d-a903e70f6843
md"""

!!! question
    Modify the code below.
"""

# ╔═╡ 0926de71-d426-4404-9cd2-80dbaa52ddc2
md"""

!!! danger "Answer"
    The modified code is in the cell below.

"""

# ╔═╡ c7c1fdee-5f9c-11eb-00bb-bd871c7f7d92
clean21 = let 
		clean2.labor = clean2[!,:socwkFT]*1.0 + clean2[!,:ptcarePT]*0.5 + clean2[!,:dietFT]*1.0 + clean2[!,:nursePT]*0.5 + clean2[!,:socwkPT]*0.5 + clean2[!,:dietPT]*0.5 + clean2[!,:nurseFT]*1.0 + clean2[!,:ptcareFT]*1.0
        
		clean2
end;

# ╔═╡ 70b24c85-dcfb-4ab4-bee9-7ba993686290
md"""

!!! warning 
    Pluto's depedency detection and reactivity can be broken by modifying variables in place. Creating a cell that contains only
    ```julia
    clean2.labor = clean2[!,:nursePT]*2 
    ```
    would be allowed, but Pluto will not recognize that modifying such a cell requires re-running all cells that reference clean2 afterward.

    The somewhat clumsy intermediate dataframes `clean1`, `clean2`, ... help fix the problem. See [this issue for some discussion](https://github.com/fonsp/Pluto.jl/issues/564).
"""

# ╔═╡ ca02b9ee-5f9d-11eb-14f2-b54ef6111837
md"""
#### Hiring

We should create hiring for the control function. There is `panellag` function in `Dialysis.jl` to help doing so.

!!! question
    Should hiring at time $t$ be $labor_{t} - labor_{t-1}$ or $labor_{t+1}-labor_{t}$? In other words, should it be a backward or forward difference? Check in the paper if needed and modify the code below accordingly.
"""

# ╔═╡ fdc155a8-93de-4b5e-b0f9-95b1bca504ab
md"""

!!! danger "Answer"
    As per Grieco & McDevitt (2017) Section 3.2, the dialysis center observes 	productivity in period $t$ after producing and then makes its hiring decision. The newly hired workers become available at the start of period $t+1$. Therefore hiring at time $t$ should be $labor_{t+1}-labor_{t}$. This is reflected in the code below.

"""

# ╔═╡ 8629935e-5f9e-11eb-0073-7b28899deac5
clean22 = let
	clean21.hiring = panellag(:labor,clean21, :provfs, :year, -1) - clean21.labor
	
	clean21
end;

# ╔═╡ 2729eb0a-5fa2-11eb-2176-4fcbb5cb1c44
md"""
#### Output

There are a few possible output measures in the data.

CMS observes mortality for most, but possibly not all, dialysis patients. To compute mortality rates, the data reports the number of treated patient-years whose mortality will be observed in column `dy`.

CMS only observes hospitalization for patients whose hospitalization is insured by Medicare. This is a smaller set of patients than those for whom mortality is observed. This number of patient years is in column `hdy`. (If I recall correctly, the output reported by @grieco2017 has summary statistics close to `hdy`).

The column `phd` report patient-months of hemodialysis. My understanding is that this number/12 should be close to `dy`. Since there are other forms of dialysis, `dy` might be larger. On the other hand if there are hemodialysis patients whose mortality is not known, then `phd` could be larger.

There might also be other reasonable variables to measure output that I have missed.


!!! question
    Choose one (or more) measure of output to use in the tables and figures below and any subsequent analysis.
"""

# ╔═╡ d6e5bb2a-4fe5-4f5e-95e5-3c41e45e98b9
md"""

!!! danger "Answer"
    For measures of output, I will use `dy` which measures "patient-years at risk of mortality" and `hdy` which measures "years at risk of hospitalization days". The descriptions for each of these variables come from object `datadic`.

"""

# ╔═╡ edd421a8-c4a3-4fcf-acc9-7f8e90c5537f
datadic

# ╔═╡ d6305b3a-5f9e-11eb-163d-736097666c33
md"""
#### For-profit and chain indicators

!!! question
    Create a boolean forprofit indicator from the `owner_f` column, and Fresenius and Davita chain indicators from `chainnam`
"""

# ╔═╡ 23aa2871-9d0b-4d99-a0d9-0fd8ff72a153
md"""

!!! danger "Answer"
    Below is the code to create the boolean forprofit indicator. Additionally, code has been added to create the boolean variable for the Davita chain of dialysis centers. I have only created chain dummies for Fresenius and Davita as they have 34,113 and 36,501 centers respectively. There are no other firms that have close to the number of centers that Davita and Fresenius have. Therefore, I will only make dummies for Fresenius and Davita as they are the biggest players in the dialysis market.

"""

# ╔═╡ 5f82fc80-5f9f-11eb-0670-f57b2e1c02fc
unique(clean2.owner_f)

# ╔═╡ 9180dc5c-5f9f-11eb-1d51-cb0516deb7b5
countmap(clean2.chainnam)

# ╔═╡ 51012006-5f9f-11eb-1c62-3595a0dbd003
clean23 = let 
	clean22.forprofit = (clean22.owner_f .== "For Profit")
	f(x) = ismissing(x) ? false : occursin(r"(FRESENIUS|FMC)",x)
	clean22.fresenius = f.(clean22.chainnam)
	g(x) = ismissing(x) ? false : occursin(r"DAVITA",x)
	clean22.davita = g.(clean22.chainnam)

	clean22
	
end;

# ╔═╡ 0b4f51ca-5fa1-11eb-1466-4959a7e056ae
md"""

#### State Inspection Rates

State inspection rates are a bit more complicated to create.
"""

# ╔═╡ 5c8d4f8e-5ff3-11eb-0c55-d1a3795358e3
clean3 = let 
	# compute days since most recent inspection
	inspect = combine(groupby(clean23, :provfs), 
		:surveydt_f => x->[unique(skipmissing(x))])
	rename!(inspect, [:provfs, :inspection_dates])
	df=innerjoin(clean23, inspect, on=:provfs)
	@assert nrow(df)==nrow(clean23)
	function dayssince(year, dates) 
		today = Date(year, 12, 31)
		past = [x.value for x in today .- dates if x.value>=0]
		if length(past)==0
			return(missing)
		else
			return(minimum(past))
		end
	end
	
	df=transform(df, [:year, :inspection_dates] => (y,d)->dayssince.(y,d))	
	rename!(df, names(df)[end] =>:days_since_inspection)
	df[!,:inspected_this_year] = ((df[!,:days_since_inspection].>=0) .&
		(df[!,:days_since_inspection].<365))
	
	# then take the mean by state
	stateRates = combine(groupby(df, [:state, :year]),
                	:inspected_this_year => 
			(x->mean(skipmissing(x))) => :state_inspection_rate)
	df = innerjoin(df, stateRates, on=[:state, :year])
	@assert nrow(df)==nrow(clean2)
	df
end

# ╔═╡ 1d6b90b2-5fa1-11eb-0b52-b36c3642539a
md"""
#### Competitors

Creating the number of competitors in the same city is somewhat
similar. Note that @grieco2017 use the number of competitors in the
same HSA, which would be preferrable. However, this dataset does not
contain information on HSAs. If you are feeling ambitious, you could
try to find data linking city, state to HSA, and use that to calculate
competitors in the same HSA.

"""

# ╔═╡ 00c8ef48-5ff8-11eb-1cf3-f7d391228226
clean4=let 
	df = clean3
	upcase(x) = Base.uppercase(x)
	upcase(m::Missing) = missing
	df[!,:provcity] = upcase.(df[!,:provcity])
	comps = combine(groupby(df,[:provcity,:year]),
    	       		:dy => 
			(x -> length(skipmissing(x).>=0.0)) => 
			:competitors
           )
	comps = comps[.!ismissing.(comps.provcity),:]
 	df = outerjoin(df, comps, on = [:provcity,:year], matchmissing=:equal)	
	@assert nrow(df)==nrow(clean3)
	df
end

# ╔═╡ 28b76e70-5fa1-11eb-31de-d12718c8de03
md"""

## Summary Statistics

!!! question
    Create a table (or multiple tables) similar to Tables 1-3 of @grieco2017.
    Comment on any notable differences. The following code
    will help you get started.
"""

# ╔═╡ 1790c00d-7a67-42db-b116-53e879608eae
md"""

!!! danger "Answer"
	Below is the replication of Tables 1-3 from @grieco2017. Before creating the tables we must create variables for "zero net hiring", "zero net investment", "excess mortality", and "time since inspection".

	"Zero net hiring" will be defined as when net hiring is equal to zero. The code for creating the variable is below. 

	"Zero net investment" will be defined as when net investment is equal to zero. I first have to find the net investment which I do in the same manor as when we found hiring earlier. The code to create the dummy variable is below.

	"Excess mortality" is the ratio of actual deaths to expected deaths as per the footnote on Table 1 from @grieco2017. The code to find the ratio is below.

	"Time Since Inspection" is listed in years by @grieco2017 but it is listed in days in the dataset so I will divide the variable by 365 to get years since inspection. The code to do this is below.

"""

# ╔═╡ e66e5ec8-8e92-448c-a659-8f44801adfff
clean41=let
	clean4.zero_net_hire = (clean4.hiring .== 0) #Make the zero net hire dummy
	
	clean4.zero_net_investment = (panellag(:totstas_f, clean4, :provfs, :year, -1) - clean4.totstas_f .== 0) #Make the zero net investment dummy

	clean4.excess_mortality = clean4.dea ./ clean4.exd #Calculate excess mortality as deaths/expected deaths

	clean4.time_since_inspection = clean4.days_since_inspection ./ 365 #convert days since inspected to years since inspection
	
	clean4
	
end;

# ╔═╡ a4ae6fb8-5fa1-11eb-1113-a565d047be6d
let
	# at the very least, you will need to change this list
	vars = [:dy, :labor, :hiring, :zero_net_hire, :totstas_f, :zero_net_investment, :sepi, :excess_mortality]

	# You shouldn't neeed to change this function, but you can if you want
	function summaryTable(df, vars;
    	                  funcs=[mean, std, x->length(collect(x))],
	                      colnames=[:Variable, :Mean, :StdDev, :N])
  		# In case you want to search for information about the syntax used here,
	  	# [XXX for XXX] is called a comprehension
  		# The ... is called the splat operator
  		DataFrame([vars [[f(skipmissing(df[!,v])) for v in vars] for f in funcs]...], colnames)
	end
	summaryTable(clean41, vars)
end

# ╔═╡ 753170e8-4c68-4e1e-ade2-e1e51b7f245c
md"""

!!! danger "Answer Continued"
	Above is my replication for Table 1 from @grieco2017. The major differences between my table and the table from the paper is that `dy` or "patient years  at risk of mortality" is 16 years higher on average in my table as opposed to Grieco and McDevitt's. Furthermore, `labor` or "FTE staff" is lower on average by 1 full-time staff member than in Grieco and McDevitt's table.

	Below is my replication for Table 2. There does not appear to be information on the number of patients referred by nephrologists in the dataset so I have omitted that variable. One difference between my table and Grieco & McDevitt's is that state inspection rate is reported as a rate rather than a percentage. Additionally, the average time since inspection in my table is 0.5 years higher than in Grieco & McDevitt's table.

	When creating the table below I had to edit the code slightly to omit missing observations when calculating mean and standard deviation as the values were coming up as NaN. The code to omit missing observations is included in the code to make the table below.

"""

# ╔═╡ fe0702b3-8fc7-4add-b7c9-e6f688408df1
let
	# at the very least, you will need to change this list
	vars = [:state_inspection_rate, :time_since_inspection, :competitors, :forprofit]

	# You shouldn't neeed to change this function, but you can if you want
	function summaryTable(df, vars;
    	                  funcs=[y->mean(filter(!isnan, y)), z -> std(filter(!isnan,z)), x->length(collect(x))],
	                      colnames=[:Variable, :Mean, :StdDev, :N])
  		# In case you want to search for information about the syntax used here,
	  	# [XXX for XXX] is called a comprehension
  		# The ... is called the splat operator
  		DataFrame([vars [[f(skipmissing(df[!,v])) for v in vars] for f in funcs]...], colnames)
	end
	summaryTable(clean41, vars)
end

# ╔═╡ a54d12d1-9389-46a3-9923-4543ce444b45
md"""

!!! danger "Answer Continued"
	
	Below is my replication for Table 3. The percentage of patients with AV fistulas is 12 percentage points higher in my table. Patients also have 1.4 additional comorbidities on average in my table as compared to Grieco & McDevitt's. Finally, average haemoglobin levels are lower in the 2008-2019 sample.

"""

# ╔═╡ fdd29235-5ae5-4e9d-be11-8d39bd6b2b6e
let
	# at the very least, you will need to change this list
	vars = [:age, :sex, :ppavf, :clmcntcom, :vin, :hgm]

	# You shouldn't neeed to change this function, but you can if you want
	function summaryTable(df, vars;
    	                  funcs=[mean, std, x->length(collect(x))],
	                      colnames=[:Variable, :Mean, :StdDev, :N])
  		# In case you want to search for information about the syntax used here,
	  	# [XXX for XXX] is called a comprehension
  		# The ... is called the splat operator
  		DataFrame([vars [[f(skipmissing(df[!,v])) for v in vars] for f in funcs]...], colnames)
	end
	summaryTable(clean41, vars)
end

# ╔═╡ 7bfe6fee-5fa3-11eb-3f31-59a77a78f035
md"""

## Figures

!!! question
    Create some figures to explore the data. Try to
    be creative.  Are there any strange patterns or other obvious
    problems with the data?
"""

# ╔═╡ 19fecb37-ad0a-417d-ab93-de8f7ebfc4bf
md"""

!!! danger "Answer"
	
	Below are two graphs, the first shows the relationship between each firm's labour and their output `dy`. The second shows the relationship between the number of dialysis stations per firm and the output of each firm `dy`.

	I have created a slider that filters the graphs to only show observations for the selected year.

	It can be seen that the relationship between output and labour as well as between output and capital (number of stations) is more or less constant over the time span of the dataset. This would lead me to believe that there were no significant productivity shocks to labour or capital faced by dialysis firms between 2008 and 2019. I also decided to make the distinction between for profit and non-profit firms as there may be differing incentives for adopting new technologies.

"""

# ╔═╡ 96bc9ea6-2f65-4e9c-981f-4027458c8a21
md"Year: 2008 $(@bind year Slider(2008:2019)) 2019"

# ╔═╡ 73c4d839-24d6-47dc-9114-8853ab9729d4
df1 = filter(:year => y -> y==year, clean41);

# ╔═╡ 7bd3ca07-6818-411e-aa7e-a26c3239f530
    @df df1 scatter(
	:labor,
    :dy,
    group = :forprofit,
    title = year,
    xlabel = "Labour",
    ylabel = "Output (dy)",
	labels = ["Non-Profit" "For Profit"],
	xlim = [0,200],
	ylim = [0,500]
)

# ╔═╡ 4696424d-f7ac-4733-88b6-2b804e4f26d1
    @df df1 scatter(
	:totstas_f,
    :dy,
    group = :forprofit,
    title = year,
    xlabel = "Stations",
    ylabel = "Output (dy)",
	labels = ["Non-Profit" "For Profit"],
	xlim = [0,200],
	ylim = [0,500]
)

# ╔═╡ c09dd940-5ff9-11eb-0db4-bf9f169c5508
md"""

!!! question
    Please hand in both your modified `dialysis-1.jl` and an html export of it. Use the triangle and circle icon at the top of the page to export it.
"""

# ╔═╡ cdf953eb-a153-42de-8f75-adbddccd634f
md"""

!!! danger "Answer"
	
	Done! :)

"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Dates = "ade2ca70-3891-5945-98fb-dc099432e06a"
Dialysis = "9b71aec8-1451-11e9-12ed-579ec60579c4"
Pkg = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
StatsPlots = "f3b207a7-027a-5e70-b257-86293d7955fd"
VegaLite = "112f6efa-9a02-5b7d-90c0-432ed331239a"

[compat]
DataFrames = "~1.4.4"
Dialysis = "~0.1.0"
Plots = "~1.38.1"
PlutoUI = "~0.7.49"
StatsBase = "~0.33.21"
StatsPlots = "~0.15.4"
VegaLite = "~2.6.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.5"
manifest_format = "2.0"
project_hash = "a27044a7b418a89ed3b7cef287477eb262af391e"

[[deps.AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "69f7020bd72f069c219b5e8c236c1fa90d2cb409"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.2.1"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "195c5505521008abea5aee4f96930717958eac6f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.4.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Arpack]]
deps = ["Arpack_jll", "Libdl", "LinearAlgebra", "Logging"]
git-tree-sha1 = "9b9b347613394885fd1c8c7729bfc60528faa436"
uuid = "7d9fca2a-8960-54d3-9f78-7d1dccf2cb97"
version = "0.5.4"

[[deps.Arpack_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "OpenBLAS_jll", "Pkg"]
git-tree-sha1 = "5ba6c757e8feccf03a1554dfaf3e26b3cfc7fd5e"
uuid = "68821587-b530-5797-8361-c406ea357684"
version = "3.5.1+1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BitFlags]]
git-tree-sha1 = "43b1a4a8f797c1cddadf60499a8a077d4af2cd2d"
uuid = "d1d4a3ce-64b1-5f1a-9ba4-7e7e69966f35"
version = "0.1.7"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "SentinelArrays", "SnoopPrecompile", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "c700cce799b51c9045473de751e9319bdd1c6e94"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.9"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "c6d890a52d2c4d55d326439580c3b8d0875a77d9"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.7"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "38f7a08f19d8810338d4f5085211c7dfa5d5bdd8"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.4"

[[deps.Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "Random", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "64df3da1d2a26f4de23871cd1b6482bb68092bd5"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.14.3"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Random", "SnoopPrecompile"]
git-tree-sha1 = "aa3edc8f8dea6cbfa176ee12f7c2fc82f0608ed3"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.20.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "600cc5508d66b78aae350f7accdb58763ac18589"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.10"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "fc08e5930ee9a4e03f84bfb5211cb54e7769758a"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.10"

[[deps.Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "00a2cccc7f098ff3b66806862d275ca3db9e6e5a"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.5.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.1+0"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "fb21ddd70a051d882a1686a5a550990bbe371a95"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.4.1"

[[deps.Contour]]
git-tree-sha1 = "d05d9e7b7aedff4e5b51a029dced05cfb6125781"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.2"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "e8119c1a33d267e16108be441a287a6981ba1630"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.14.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SnoopPrecompile", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "d4f69885afa5e6149d0cab3818491565cf41446d"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.4.4"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.DataValues]]
deps = ["DataValueInterfaces", "Dates"]
git-tree-sha1 = "d88a19299eba280a6d062e135a43f00323ae70bf"
uuid = "e7dc6d0d-1eca-5fa6-8ad6-5aecde8b7ea5"
version = "0.4.13"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.Dialysis]]
deps = ["CSV", "DataFrames", "Distributions", "FixedEffectModels", "ForwardDiff", "LinearAlgebra", "ShiftedArrays", "Statistics", "ZipFile"]
git-tree-sha1 = "bdef12b009249530e44d5097b119790d55e5206c"
uuid = "9b71aec8-1451-11e9-12ed-579ec60579c4"
version = "0.1.0"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "c5b6685d53f933c11404a3ae9822afe30d522494"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.12.2"

[[deps.Distances]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "3258d0659f812acde79e8a74b11f17ac06d0ca04"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.7"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "74911ad88921455c6afcad1eefa12bd7b1724631"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.80"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bad72f730e9e91c08d9427d5e8db95478a3c323d"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.4.8+0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Pkg", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "74faea50c1d007c85837327f6775bea60b5492dd"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.2+2"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "90630efff0894f8142308e334473eba54c433549"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.5.0"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "7be5f99f7d15578798f338f5433b6c432ea8037b"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.16.0"

[[deps.FilePaths]]
deps = ["FilePathsBase", "MacroTools", "Reexport", "Requires"]
git-tree-sha1 = "919d9412dbf53a2e6fe74af62a73ceed0bce0629"
uuid = "8fc22ac5-c921-52a6-82fd-178b2807b824"
version = "0.8.3"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "e27c4ebe80e8699540f2d6c805cc12203b614f12"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.20"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "9a0472ec2f5409db243160a8b030f94c380167a3"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.13.6"

[[deps.FixedEffectModels]]
deps = ["DataFrames", "FixedEffects", "LinearAlgebra", "Printf", "Reexport", "Statistics", "StatsAPI", "StatsBase", "StatsFuns", "StatsModels", "Tables", "Vcov"]
git-tree-sha1 = "fe8ff72b50e10e545e0beea0679fdf36afb4f1f3"
uuid = "9d5cd8c9-2029-5cab-9928-427838db53e3"
version = "1.7.0"

[[deps.FixedEffects]]
deps = ["GroupedArrays", "LinearAlgebra", "Printf", "Requires", "StatsBase"]
git-tree-sha1 = "06c114eaad4566df6287c5d303c194309f923efb"
uuid = "c8885935-8500-56a7-9867-7708b20db0eb"
version = "2.1.1"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "a69dd6db8a809f78846ff259298678f0d6212180"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.34"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "d972031d28c8c8d9d7b41a536ad7bb0c2579caca"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.8+0"

[[deps.GR]]
deps = ["Artifacts", "Base64", "DelimitedFiles", "Downloads", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Preferences", "Printf", "Random", "Serialization", "Sockets", "TOML", "Tar", "Test", "UUIDs", "p7zip_jll"]
git-tree-sha1 = "387d2b8b3ca57b791633f0993b31d8cb43ea3292"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.71.3"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "5982b5e20f97bff955e9a2343a14da96a746cd8c"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.71.3+0"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "d3b3624125c1474292d0d8ed0f65554ac37ddb23"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.74.0+2"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.GroupedArrays]]
deps = ["DataAPI", "Missings"]
git-tree-sha1 = "44c812379b629eea08b6d25a196010f1f4b001e3"
uuid = "6407cd72-fade-4a84-8a1e-56e431fc1533"
version = "0.3.3"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "Dates", "IniFile", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "OpenSSL", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "eb5aa5e3b500e191763d35198f859e4b40fff4a6"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.7.3"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions", "Test"]
git-tree-sha1 = "709d864e3ed6e3545230601f94e11ebc65994641"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.11"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "0cf92ec945125946352f3d46c96976ab972bde6f"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.3.2"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "721ec2cf720536ad005cb38f50dbba7b02419a15"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.14.7"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "49510dfcb407e572524ba94aeae2fced1f3feb0f"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.8"

[[deps.InvertedIndices]]
git-tree-sha1 = "82aec7a3dd64f4d9584659dc0b62ef7db2ef3e19"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.2.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLFzf]]
deps = ["Pipe", "REPL", "Random", "fzf_jll"]
git-tree-sha1 = "f377670cda23b6b7c1c0b3893e37451c5c1a2185"
uuid = "1019f520-868f-41f5-a6de-eb00f4b6a39c"
version = "0.1.5"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.JSONSchema]]
deps = ["HTTP", "JSON", "URIs"]
git-tree-sha1 = "8d928db71efdc942f10e751564e6bbea1e600dfe"
uuid = "7d188eb4-7ad8-530c-ae41-71a32a6d4692"
version = "1.0.1"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b53380851c6e6664204efb2e62cd24fa5c47e4ba"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.2+0"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "9816b296736292a80b9a3200eb7fbb57aaa3917a"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.5"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Printf", "Requires"]
git-tree-sha1 = "2422f47b34d4b127720a18f86fa7b1aa2e141f29"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.18"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "6f73d1dd803986947b2c750138528a999a6c7733"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.6.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c7cb1f5d892775ba13767a87c7ada0b980ea0a71"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+2"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "946607f84feb96220f480e0422d3484c49c00239"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.19"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "cedb76b37bc5a6c702ade66be44f831fa23c681e"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "1.0.0"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "2ce8695e1e699b68702c03402672a69f54b8aca9"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2022.2.0+0"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "42324d08725e200c23d4dfb549e0d5d89dede2d2"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.10"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "Random", "Sockets"]
git-tree-sha1 = "03a9b9718f5682ecb107ac9f7308991db4ce395b"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.7"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.MultivariateStats]]
deps = ["Arpack", "LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI", "StatsBase"]
git-tree-sha1 = "efe9c8ecab7a6311d4b91568bd6c88897822fabe"
uuid = "6f286f6a-111f-5878-ab1e-185364afe411"
version = "0.10.0"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "a7c3d1da1189a1c2fe843a3bfa04d18d20eb3211"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.1"

[[deps.NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "2c3726ceb3388917602169bed973dbc97f1b51a8"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.13"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.NodeJS]]
deps = ["Pkg"]
git-tree-sha1 = "905224bbdd4b555c69bb964514cfa387616f0d3a"
uuid = "2bd173c7-0d6d-553b-b6af-13a54713934c"
version = "1.3.0"

[[deps.Observables]]
git-tree-sha1 = "6862738f9796b3edc1c09d0890afce4eca9e7e93"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.5.4"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "f71d8950b724e9ff6110fc948dff5a329f901d64"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.8"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSSL]]
deps = ["BitFlags", "Dates", "MozillaCACerts_jll", "OpenSSL_jll", "Sockets"]
git-tree-sha1 = "6503b77492fd7fcb9379bf73cd31035670e3c509"
uuid = "4d8831e6-92b7-49fb-bdf8-b643e874388c"
version = "1.3.3"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6e9dba33f9f2c44e08a020b0caf6903be540004"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.19+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.40.0+0"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "cf494dca75a69712a72b80bc48f59dcf3dea63ec"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.16"

[[deps.Parsers]]
deps = ["Dates", "SnoopPrecompile"]
git-tree-sha1 = "8175fc2b118a3755113c8e68084dc1a9e63c61ee"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.3"

[[deps.Pipe]]
git-tree-sha1 = "6842804e7867b115ca9de748a0cf6b364523c16d"
uuid = "b98c9c47-44ae-5843-9183-064241ee97a0"
version = "1.3.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "1f03a2d339f42dca4a4da149c7e15e9b896ad899"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.1.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "SnoopPrecompile", "Statistics"]
git-tree-sha1 = "5b7690dd212e026bbab1860016a6601cb077ab66"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.3.2"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "JLFzf", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "Preferences", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "RelocatableFolders", "Requires", "Scratch", "Showoff", "SnoopPrecompile", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "Unzip"]
git-tree-sha1 = "a99bbd3664bb12a775cda2eba7f3b2facf3dad94"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.38.2"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "eadad7b14cf046de6eb41f13c9275e5aa2711ab6"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.49"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "LaTeXStrings", "Markdown", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "96f6db03ab535bdb901300f88335257b0018689d"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.2.2"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "0c03844e2231e12fda4d0086fd7cbe4098ee8dc5"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+2"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "97aa253e65b784fd13e83774cadc95b38011d734"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.6.0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "dc84268fe0e3335a62e315a3a7cf2afa7178a734"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.3"

[[deps.RecipesBase]]
deps = ["SnoopPrecompile"]
git-tree-sha1 = "261dddd3b862bd2c940cf6ca4d1c8fe593e457c8"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.3"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase", "SnoopPrecompile"]
git-tree-sha1 = "e974477be88cb5e3040009f3767611bc6357846f"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.11"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "90bc7a7c96410424509e4263e277e43250c05691"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "1.0.0"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "f94f779c94e58bf9ea243e77a37e16d9de9126bd"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.1"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "c02bd3c9c3fc8463d3591a62a378f90d2d8ab0f3"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.3.17"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.ShiftedArrays]]
git-tree-sha1 = "503688b59397b3307443af35cd953a13e8005c16"
uuid = "1277b4bf-5013-50f5-be3d-901d8477a67a"
version = "2.0.0"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.SnoopPrecompile]]
deps = ["Preferences"]
git-tree-sha1 = "e760a70afdcd461cf01a575947738d359234665c"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "a4ada03f999bd01b3a25dcaa30b2d929fe537e00"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.0"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "d75bda01f8c31ebb72df80a46c88b25d1c79c56d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.7"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "6954a456979f23d05085727adb17c4551c19ecd1"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.12"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6b7ba252635a5eff6a0b0664a41ee140a1c9e72a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f9af7f195fb13589dd2e2d57fdb401717d2eb1f6"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.5.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "HypergeometricFunctions", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "ab6083f09b3e617e34a956b43e9d51b824206932"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.1.1"

[[deps.StatsModels]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "Printf", "REPL", "ShiftedArrays", "SparseArrays", "StatsBase", "StatsFuns", "Tables"]
git-tree-sha1 = "a5e15f27abd2692ccb61a99e0854dfb7d48017db"
uuid = "3eaba693-59b7-5ba5-a881-562e759f1c8d"
version = "0.6.33"

[[deps.StatsPlots]]
deps = ["AbstractFFTs", "Clustering", "DataStructures", "DataValues", "Distributions", "Interpolations", "KernelDensity", "LinearAlgebra", "MultivariateStats", "NaNMath", "Observables", "Plots", "RecipesBase", "RecipesPipeline", "Reexport", "StatsBase", "TableOperations", "Tables", "Widgets"]
git-tree-sha1 = "e0d5bc26226ab1b7648278169858adcfbd861780"
uuid = "f3b207a7-027a-5e70-b257-86293d7955fd"
version = "0.15.4"

[[deps.StringManipulation]]
git-tree-sha1 = "46da2434b41f41ac3594ee9816ce5541c6096123"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.0"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.TableOperations]]
deps = ["SentinelArrays", "Tables", "Test"]
git-tree-sha1 = "e383c87cf2a1dc41fa30c093b2a19877c83e1bc1"
uuid = "ab02a1b2-a7df-11e8-156e-fb1833f50b87"
version = "1.2.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.TableTraitsUtils]]
deps = ["DataValues", "IteratorInterfaceExtensions", "Missings", "TableTraits"]
git-tree-sha1 = "78fecfe140d7abb480b53a44f3f85b6aa373c293"
uuid = "382cd787-c1b6-5bf2-a167-d5b971a19bda"
version = "1.0.2"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "c79322d36826aa2f4fd8ecfa96ddb47b174ac78d"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.1"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "94f38103c984f89cf77c402f2a68dbd870f8165f"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.11"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.URIParser]]
deps = ["Unicode"]
git-tree-sha1 = "53a9f49546b8d2dd2e688d216421d050c9a31d0d"
uuid = "30578b45-9adc-5946-b283-645ec420af67"
version = "0.4.1"

[[deps.URIs]]
git-tree-sha1 = "ac00576f90d8a259f2c9d823e91d1de3fd44d348"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unzip]]
git-tree-sha1 = "ca0969166a028236229f63514992fc073799bb78"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.2.0"

[[deps.Vcov]]
deps = ["Combinatorics", "GroupedArrays", "LinearAlgebra", "StatsAPI", "StatsBase", "Tables"]
git-tree-sha1 = "2ba425b1f94f0915c4552fd1f94b267da760e89f"
uuid = "ec2bfdc2-55df-4fc9-b9ae-4958c2cf2486"
version = "0.6.0"

[[deps.Vega]]
deps = ["DataStructures", "DataValues", "Dates", "FileIO", "FilePaths", "IteratorInterfaceExtensions", "JSON", "JSONSchema", "MacroTools", "NodeJS", "Pkg", "REPL", "Random", "Setfield", "TableTraits", "TableTraitsUtils", "URIParser"]
git-tree-sha1 = "c6bd0c396ce433dce24c4a64d5a5ab6dc8e40382"
uuid = "239c3e63-733f-47ad-beb7-a12fde22c578"
version = "2.3.1"

[[deps.VegaLite]]
deps = ["Base64", "DataStructures", "DataValues", "Dates", "FileIO", "FilePaths", "IteratorInterfaceExtensions", "JSON", "MacroTools", "NodeJS", "Pkg", "REPL", "Random", "TableTraits", "TableTraitsUtils", "URIParser", "Vega"]
git-tree-sha1 = "3e23f28af36da21bfb4acef08b144f92ad205660"
uuid = "112f6efa-9a02-5b7d-90c0-432ed331239a"
version = "2.6.0"

[[deps.Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "ed8d92d9774b077c53e1da50fd81a36af3744c1c"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+0"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4528479aa01ee1b3b4cd0e6faef0e04cf16466da"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.25.0+0"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.Widgets]]
deps = ["Colors", "Dates", "Observables", "OrderedCollections"]
git-tree-sha1 = "fcdae142c1cfc7d89de2d11e08721d0f2f86c98a"
uuid = "cc8bc4a8-27d6-5769-a93b-9d913e69aa62"
version = "0.6.6"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[deps.WorkerUtilities]]
git-tree-sha1 = "cd1659ba0d57b71a464a29e64dbc67cfe83d54e7"
uuid = "76eceee3-57b5-4d4a-8e66-0e911cebbf60"
version = "1.6.1"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "93c41695bc1c08c46c5899f4fe06d6ead504bb73"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.10.3+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.ZipFile]]
deps = ["Libdl", "Printf", "Zlib_jll"]
git-tree-sha1 = "f492b7fe1698e623024e873244f10d89c95c340a"
uuid = "a5390f91-8eb1-5f08-bee0-b1d1ffed6cea"
version = "0.10.1"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e45044cd873ded54b6a5bac0eb5c971392cf1927"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.2+0"

[[deps.fzf_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "868e669ccb12ba16eaf50cb2957ee2ff61261c56"
uuid = "214eeab7-80f7-51ab-84ad-2988db7cef09"
version = "0.29.0+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a2ea60308f0996d26f1e5354e10c24e9ef905d4"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.4.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "9ebfc140cc56e8c2156a15ceac2f0302e327ac0a"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+0"
"""

# ╔═╡ Cell order:
# ╟─d5554696-5f6f-11eb-057f-a79641cf483a
# ╟─ad1cc4c6-5f72-11eb-35d5-53ff88f1f041
# ╟─85ab85ff-6986-46e5-b8ba-6c80ccca8a3e
# ╠═5c1aeb4f-fef2-41d0-813f-eb78728ea83b
# ╠═24722a1a-7213-40ae-9fc8-e9e59924b758
# ╠═b2c0299f-5711-4071-8c29-b78616e5f874
# ╠═c6f8ecfe-0e81-45a9-b7e6-a9ff629b549b
# ╠═9e653793-a4dc-4843-980b-d8921303422f
# ╟─7b4ecdee-5f73-11eb-388c-4d6f9719d79b
# ╟─a75918ae-5f73-11eb-3a3e-2f64c0dcc49c
# ╠═a80227f8-5f77-11eb-1211-95dd2c151877
# ╠═b9e1f8de-5f77-11eb-25b8-57e263315ac3
# ╟─a06995aa-5f78-11eb-3939-f9aca087b12c
# ╠═5b2d6ebe-5f78-11eb-0528-ab36ae696a35
# ╟─5ea12c9c-5f79-11eb-34e7-2d7f07854b31
# ╟─95ad1f3c-5f79-11eb-36fb-1b384c84317c
# ╠═ca038b54-5f79-11eb-0851-9f684e3bb83f
# ╟─cfaabda0-5f79-11eb-17e4-a7cd045681da
# ╠═c642b578-5f77-11eb-1346-15a35500e61f
# ╠═3d6cf930-5f80-11eb-04a1-0f608e26886b
# ╟─c7192aba-5fe8-11eb-1d50-81cb0f959b4a
# ╟─600c6368-5f80-11eb-24b1-c35a333d7164
# ╠═bcaf264a-5f77-11eb-2bf5-1bd3c16dbce6
# ╠═46da23f6-5f82-11eb-2c42-dbcf1c09192e
# ╟─65d2d0e8-5f85-11eb-2e4b-b3e561a1a63c
# ╠═81b220c8-5f82-11eb-141a-53ed12752330
# ╟─1f577cac-5feb-11eb-19c7-2ff4856aee9d
# ╠═3f871682-5f86-11eb-2c50-971aa2d55aec
# ╟─34fa745c-5fec-11eb-3c3c-67eba7bffa6e
# ╟─985c4280-5fec-11eb-362b-21e463e63f8d
# ╠═7c756c72-5f83-11eb-28d5-7b5654c51ea3
# ╟─8c8cab5a-5f85-11eb-1bb0-e506d437545d
# ╠═57324928-5f83-11eb-3e9f-4562c8b03cd4
# ╠═a3452e58-5f85-11eb-18fb-e5f00173defb
# ╠═f6620c93-56fd-45b4-9b4e-6cb6ec8736c7
# ╠═bff2e0a8-5f86-11eb-24fd-9504f5c47ffb
# ╟─f895392e-5f8b-11eb-1d7a-3f9c6c5ce483
# ╟─123a49dc-5f8c-11eb-1c59-c5e5715b819f
# ╠═2dda9576-5f90-11eb-29eb-91dec5be5175
# ╠═0b1b8522-5f90-11eb-2f9e-91707f735fe6
# ╟─2beddacc-5f93-11eb-35a0-cfee0361b2eb
# ╠═468e9380-5f96-11eb-1e57-9bf6b185cbd1
# ╟─2632c508-5f9c-11eb-149b-edb3f5aee983
# ╠═62f7ee18-5f9d-11eb-1b6c-4dabc3f9d787
# ╟─656f7c7e-5f9d-11eb-041d-a903e70f6843
# ╟─0926de71-d426-4404-9cd2-80dbaa52ddc2
# ╠═c7c1fdee-5f9c-11eb-00bb-bd871c7f7d92
# ╟─70b24c85-dcfb-4ab4-bee9-7ba993686290
# ╟─ca02b9ee-5f9d-11eb-14f2-b54ef6111837
# ╟─fdc155a8-93de-4b5e-b0f9-95b1bca504ab
# ╠═8629935e-5f9e-11eb-0073-7b28899deac5
# ╟─2729eb0a-5fa2-11eb-2176-4fcbb5cb1c44
# ╟─d6e5bb2a-4fe5-4f5e-95e5-3c41e45e98b9
# ╠═edd421a8-c4a3-4fcf-acc9-7f8e90c5537f
# ╟─d6305b3a-5f9e-11eb-163d-736097666c33
# ╟─23aa2871-9d0b-4d99-a0d9-0fd8ff72a153
# ╠═5f82fc80-5f9f-11eb-0670-f57b2e1c02fc
# ╠═9180dc5c-5f9f-11eb-1d51-cb0516deb7b5
# ╠═51012006-5f9f-11eb-1c62-3595a0dbd003
# ╟─0b4f51ca-5fa1-11eb-1466-4959a7e056ae
# ╠═5c8d4f8e-5ff3-11eb-0c55-d1a3795358e3
# ╟─1d6b90b2-5fa1-11eb-0b52-b36c3642539a
# ╠═00c8ef48-5ff8-11eb-1cf3-f7d391228226
# ╟─28b76e70-5fa1-11eb-31de-d12718c8de03
# ╟─1790c00d-7a67-42db-b116-53e879608eae
# ╠═e66e5ec8-8e92-448c-a659-8f44801adfff
# ╟─a4ae6fb8-5fa1-11eb-1113-a565d047be6d
# ╟─753170e8-4c68-4e1e-ade2-e1e51b7f245c
# ╟─fe0702b3-8fc7-4add-b7c9-e6f688408df1
# ╟─a54d12d1-9389-46a3-9923-4543ce444b45
# ╟─fdd29235-5ae5-4e9d-be11-8d39bd6b2b6e
# ╟─7bfe6fee-5fa3-11eb-3f31-59a77a78f035
# ╠═b443a46e-5fa3-11eb-3e71-dfd0683dc6e9
# ╟─19fecb37-ad0a-417d-ab93-de8f7ebfc4bf
# ╠═96bc9ea6-2f65-4e9c-981f-4027458c8a21
# ╠═73c4d839-24d6-47dc-9114-8853ab9729d4
# ╟─7bd3ca07-6818-411e-aa7e-a26c3239f530
# ╟─4696424d-f7ac-4733-88b6-2b804e4f26d1
# ╟─c09dd940-5ff9-11eb-0db4-bf9f169c5508
# ╟─cdf953eb-a153-42de-8f75-adbddccd634f
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
