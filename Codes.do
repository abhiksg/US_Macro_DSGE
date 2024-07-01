*Importing Dataset
import excel "\\NetAppSvr-704f\cw-SII\home\sii\senga583\Desktop\DSGE Analysis\US_Econ_Ind_Fred.xlsx", sheet("Sheet1") firstrow

*Exploring Dataset
describe

*Generating time variable,setting dataset as timeseries, and sorting dataset
generate Quarter=tq(1970q1)+_n-1
format %tq Quarter
tsset Quarter
sort Quarter
 
*Tracking Sort
describe

*Renaming Variables
rename FEDFUNDS r
label variable r "Federal funds rate"

rename UNRATE un
label variable un "Unemployment rate"

*Generating annualised growth rates 
gen y= 400*(ln(GDPC1)- ln(L.GDPC1))
label variable y "Real GDP Growth"

gen c= 400*(ln(PCECC96)- ln(L.PCECC96))
label variable c "Consumption Growth"

gen p= 400*(ln(GDPDEF)- ln(L.GDPDEF))
label variable p "Inflation rate"

gen h= 400*(ln(HOANBS)- ln(L.HOANBS))
label variable h "Hourly Work"

*Eyeballing for stationarity of series
tsline y, saving(real_gdp) 
tsline p, saving(inflation_rate)
tsline h, saving(hours_worked)
tsline c, saving(cons_rate)
gr combine real_gdp.gph inflation_rate.gph hours_worked.gph cons_rate.gph, saving(ts_var)

* Running Diagonsitic-probablity density function, normality and skewness
kdensity y, kernel (epanechnikov) normal saving(y_ke)
kdensity p, kernel (epanechnikov) normal saving(p_ke)
kdensity h, kernel (epanechnikov) normal saving(h_ke)
kdensity c, kernel (epanechnikov) normal saving(c_ke)
gr combine y_ke.gph p_ke.gph h_ke.gph c_ke.gph, saving(kd_var)

qnorm y, saving(y_sk)
qnorm p, saving(p_sk)
qnorm h, saving(h_sk)
qnorm c, saving(c_sk)
gr combine y_sk.gph p_sk.gph h_sk.gph c_sk.gph, saving(qn_var)

sktest y
sktest p 
sktest h
sktest r 

*Calculating series mean and variations
egen avgy= mean(y)
label variable avgy "Real GDP Average"
gen ydev = (y-avgy)^2
label variable ydev "Real GDP Deviation"
tsline  y avgy, saving(y_avg)
tsline ydev, saving(y_dev)

egen avgp= mean(p)
label variable avgp "Inflation rt. Average"
gen pdev = (p-avgp)^2
label variable pdev  "Inflation rt. Deviation"
tsline  p avgp, saving(p_avg)
tsline pdev, saving(p_dev)

egen avgh= mean(h)
label variable avgh "Hourly Average"
gen hdev = (h-avgh)^2
label variable hdev "H.Deviation"
tsline  h avgh, saving(h_avg)
tsline hdev, saving(h_dev)

egen avgc= mean(c)
label variable avgc "Cons.Average"
gen cdev = (c-avgc)^2
label variable cdev "Cons. Deviation"
tsline  c avgc, saving(c_avg)
tsline cdev, saving(c_dev)

gr combine y_avg.gph p_avg.gph h_avg.gph c_avg.gph, saving(me_var)
gr combine y_dev.gph p_dev.gph h_dev.gph c_dev.gph, saving(de_var)

*Dickey-Fuller Test for Stationarity
dfuller y
dfuller p
dfuller h
dfuller c

*Applying Hodrick-Prescott Filter 
tsfilter hp r_gdp= y, smooth(1600) trend(gdp_trend)
tsline y gdp_trend
tsline r_gdp


** Dynamic Equation Model
 
 dsgenl (1 = {beta}*(x/F.x)*(1/g)*(r/F.p) ) ///
        (1/{phi} + (p-1) = {phi}*x + {beta}*(F.p-1)) ///
		({beta}*r = p^(1/{beta})*u) ///
		(ln(F.u) = {rhou}*ln(u)) ///
		(ln(F.g) = {rhog}*ln(g)), ///
		exostate(u g) observed(p r) unobserved(x)
		
* Estaminating beta 
nlcom _b[beta]
   _nl_1 :1/_b[beta]

*Calculating Steady State values
estat steady, compact
estat stable

*Transition and Covariance Matrix
estat policy
estat covariance
estat transition

*Impulse-Response (IR) Function

*Setting IR 
irf set irf1
*Creating response
irf create model1, replace step(48)
*Graphing impulse of u
irf graph irf, impulse(u) response(x p r u) byopts(yrescale) saving(md_1)


irf set irf2
irf create model2, replace step(48)
irf graph irf, impulse(g) response(x p r g) byopts(yrescale) saving(md_2)

*Forecasting
 estimates store dsge_est
 tsappend, add(12)
 forecast create dsgemodel
 forecast estimates dsge_est
 forecast solve, prefix(d1_) begin(tq(2024q1))
 label variable d1_p"Inflation"
 tsline d1_p p, tline(2020q1) 