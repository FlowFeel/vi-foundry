
    setwd("/Users/lauravanholstein/Python_coding/PyRate/Revisions_divdep_Nov2023/Submission/Lumped_site/NHPP-mG")
    tbl = read.table(file = "wholeclade_ltt.txt",header = T)
    pdf(file='wholeclade_ltt.pdf',width=12, height=9)
    time = -tbl$time
    library(scales)
    plot(time,tbl$diversity, type="n",ylab= "Number of lineages", xlab="Time (Ma)", main="Range-through diversity through time", ylim=c(0,8),xlim=c(min(time),0))
    polygon(c(time, rev(time)), c(tbl$M_div, rev(tbl$m_div)), col = alpha("#504A4B",0.5), border = NA)
    lines(time,tbl$diversity, type="l",lwd = 2)
    n<-dev.off()
    