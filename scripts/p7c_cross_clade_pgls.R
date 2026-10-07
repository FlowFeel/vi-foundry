library(ape); library(caper)
cat("=== CROSS-CLADE PGLS ===\n\n")

# Trees
tree1 <- read.tree(text="((((Rodentia:28,(Platyrrhini:22,(Cercopithecidae:18,Hominidae:14):6):10):18,((Eulipotyphla:18,Chiroptera:18):12,(Cetartiodactyla:25,(Carnivora:22,Canidae:19):3):7):12):25,Proboscidea:32):10,Marsupialia:40);")
tree1 <- root(tree1, outgroup="Marsupialia")
cat("Mammal tree:", Ntip(tree1), "tips\n")

tree2 <- read.tree(text="(((((Rodentia:28,(Platyrrhini:22,(Cercopithecidae:18,Hominidae:14):6):10):18,((Eulipotyphla:18,Chiroptera:18):12,(Cetartiodactyla:25,(Carnivora:22,Canidae:19):3):7):12):25,Proboscidea:32):10,Marsupialia:40):8,(Corvidae:28,Psittacidae:28):18);")
tree2 <- root(tree2, outgroup=c("Corvidae","Psittacidae"))
cat("All-vert tree:", Ntip(tree2), "tips\n")

tree3 <- read.tree(text="(((((Rodentia:28,(Platyrrhini:22,(Cercopithecidae:18,(Hominidae:14,Homo:12):2):6):10):18,((Eulipotyphla:18,Chiroptera:18):12,(Cetartiodactyla:25,(Carnivora:22,Canidae:19):3):7):12):25,Proboscidea:32):10,Marsupialia:40):8,(Corvidae:28,Psittacidae:28):18);")
cat("Homo tree:", Ntip(tree3), "tips\n")

# Data
data <- data.frame(
  clade=c("Rodentia","Chiroptera","Carnivora","Eulipotyphla","Cetartiodactyla",
          "Proboscidea","Marsupialia","Platyrrhini","Cercopithecidae","Hominidae",
          "Corvidae","Psittacidae","Canidae"),
  dd=c(-0.12,-0.10,-0.08,0,0,-0.08,-0.06,-0.05,-0.04,-0.02,0.02,0.015,-0.08),
  culture=c(0,0,0,0,0.477,0.778,0,0.778,0.954,1.602,1.041,1.200,0.300)
)

run <- function(tree, df, label) {
  cat("\n---", label, "---\n")
  df <- df[df$clade %in% tree$tip.label,]
  cat("  N =", nrow(df), "clades\n")
  comp <- comparative.data(phy=tree, data=df, names.col="clade", vcv=TRUE, warn.dropped=FALSE)
  mod <- pgls(dd ~ culture, data=comp, lambda="ML")
  s <- summary(mod)$coef
  lam <- mod$param[2]
  lm0 <- lm(dd ~ culture, data=df)
  l0 <- summary(lm0)$coef
  cat("  PGLS: slope=", round(coef(mod)[2],4), ", P=", format(s[2,4],sci=T),
      ", R²=", round(summary(mod)$r.squared,3), ", λ=", round(lam,3), "\n")
  cat("  OLS:  slope=", round(coef(lm0)[2],4), ", P=", format(l0[2,4],sci=T), "\n")
  cat("  Direction preserved:", sign(coef(mod)[2]) == sign(coef(lm0)[2]), "\n")
  c(slope=unname(coef(mod)[2]), P=s[2,4], R2=summary(mod)$r.squared, lambda=lam)
}

r1 <- run(tree1, data[!data$clade %in% c("Corvidae","Psittacidae"),], "Mammals (11)")
r2 <- run(tree2, data, "All non-Homo (13)")
dh <- rbind(data, data.frame(clade="Homo", dd=0.20, culture=2.700))
r3 <- run(tree3, dh, "All + Homo (14)")

cat("\n=== SUMMARY ===\n")
cat("Mammals:     ", paste0(round(r1,4), collapse=", "), "\n")
cat("All non-Homo:", paste0(round(r2,4), collapse=", "), "\n")
cat("+ Homo:      ", paste0(round(r3,4), collapse=", "), "\n")
saveRDS(list(mammals=r1, nonhomo=r2, homo=r3), file="results/cross-clade-pgls-results.rds")
cat("Saved.\n")