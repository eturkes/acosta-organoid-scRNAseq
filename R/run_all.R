#    This file is part of acosta-organoid-scRNAseq.
#    Copyright (C) 2022-2024  Emir Turkes, Diana Acosta, Gi Guo, Yuzhou Chang,
#    Hongjun Fu, Ohio State University Wexner Medical Center
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    Emir Turkes can be contacted at emir.turkes@eturkes.com

setwd(dirname(parent.frame(2)$ofile)) # Move to location of this file.

rmarkdown::render(
  file.path("D72_WT_rep1", "01_prep.Rmd"),
  output_file = file.path("..", "..", "results", "D72_WT_rep1", "01_prep.html")
)
rmarkdown::render(
  file.path("D72_HET_rep1", "01_prep.Rmd"),
  output_file = file.path("..", "..", "results", "D72_HET_rep1", "01_prep.html")
)
rmarkdown::render(
  file.path("D72_HOM_rep1", "01_prep.Rmd"),
  output_file = file.path("..", "..", "results", "D72_HOM_rep1", "01_prep.html")
)
rmarkdown::render(
  file.path("D72_WT_rep2", "01_prep.Rmd"),
  output_file = file.path("..", "..", "results", "D72_WT_rep2", "01_prep.html")
)
rmarkdown::render(
  file.path("D72_HET_rep2", "01_prep.Rmd"),
  output_file = file.path("..", "..", "results", "D72_HET_rep2", "01_prep.html")
)
rmarkdown::render(
  file.path("D72_HOM_rep2", "01_prep.Rmd"),
  output_file = file.path("..", "..", "results", "D72_HOM_rep2", "01_prep.html")
)
rmarkdown::render(
  file.path("D120_WT_rep1", "01_prep.Rmd"),
  output_file = file.path("..", "..", "results", "D120_WT_rep1", "01_prep.html")
)
rmarkdown::render(
  file.path("D120_HET_rep1", "01_prep.Rmd"),
  output_file = file.path("..", "..", "results", "D120_HET_rep1", "01_prep.html")
)
rmarkdown::render(
  file.path("D120_HOM_rep1", "01_prep.Rmd"),
  output_file = file.path("..", "..", "results", "D120_HOM_rep1", "01_prep.html")
)
rmarkdown::render(
  file.path("D120_WT_rep2", "01_prep.Rmd"),
  output_file = file.path("..", "..", "results", "D120_WT_rep2", "01_prep.html")
)
rmarkdown::render(
  file.path("D120_HET_rep2", "01_prep.Rmd"),
  output_file = file.path("..", "..", "results", "D120_HET_rep2", "01_prep.html")
)
rmarkdown::render(
  file.path("D120_HOM_rep2", "01_prep.Rmd"),
  output_file = file.path("..", "..", "results", "D120_HOM_rep2", "01_prep.html")
)
