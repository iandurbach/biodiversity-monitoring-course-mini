# Plotting and evaluation helpers; source from 04_sdms.
bl <- '#2952BF'; rd <- '#D11A42'; grn <- '#7D9900'
pal <- hcl.colors(80,'YlGnBu',rev=TRUE)
style <- function(mfrow=c(1,1)) {
  par(mfrow=mfrow,mar=c(3.5,3.7,2,0.8),mgp=c(2.2,0.6,0),
      las=1,bty='l',cex=0.88)
}
auc_pb <- function(p,b) {
  # Hijmans & Elith (2023), section 5.3: pairwise ranking, ties count half.
  stopifnot(length(p)>0,length(b)>0,all(is.finite(c(p,b))))
  ranks <- rank(c(p,b),ties.method='average')
  (sum(ranks[seq_along(p)])-length(p)*(length(p)+1)/2)/(length(p)*length(b))
}
map_plot <- function(r,main='',points=NULL,zlim=NULL) {
  # Axes use illustrative UTM coordinates; maps always labelled schematic.
  plot(r,col=pal,main=main,axes=FALSE,range=zlim,
       plg=list(cex=0.75),mar=c(0.5,0.5,2,3.5))
  if (!is.null(points)) points(points,pch=16,cex=0.45,col=rd)

}
flowchart <- function(labels) {
 par(mar=rep(0,4)); n <- length(labels)
 plot(0,0,type='n',xlim=c(0,10),ylim=c(0,n),axes=FALSE,xlab='',ylab='')
 for(i in seq_len(n)) {
  y <- n-i+0.5
  rect(1,y-0.32,9,y+0.32,col=adjustcolor(bl,0.1),border=bl)
  text(5,y,labels[i],cex=0.98)
  if(i<n) arrows(5,y-0.34,5,y-0.63,length=0.08,col=bl,lwd=2)
 }
}
