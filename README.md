# Acosta Organoid scRNAseq
#### *Please visit [https://github.com/eturkes/acosta-organoid-scRNAseq](https://github.com/eturkes/acosta-organoid-scRNAseq) for the latest version of this codebase.*

Analysis of organoid lines modeling FTD with Alzheimer's-like phenotype.  
This repo contains all code to reproduce the analysis.  
Required processed data is available at: [Dropbox Link](https://www.dropbox.com/scl/fo/z50uy5cl5qoo56rjmlz8g/AHderLDov3AaJ18vh1PFxt8?rlkey=a648zfsfjvog9tp2bpu9bdgxy&st=e3vbc9cy&dl=0).  
Raw data (not needed) is available at the following GEO accession: [GSM8551336](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM8551336).

```
This file is part of acosta-organoid-scRNAseq.
Copyright (C) 2022-2025  Emir Turkes, Diana Acosta, Gi Guo, Yuzhou Chang,
Hongjun Fu, Ohio State University Wexner Medical Center

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Emir Turkes can be contacted at emir.turkes@eturkes.com
```

## Reproducing the Analysis

### Brief Overview

The preferred approach for reproducing the analysis is to use Apptainer (previously called Singularity).
Apptainer is free and open-source container software similar to Docker but with privilages compatible with high-performance computing (HPC) clusters.
It allows users to use identical software environments to the OS-level, ensuring reproducibility and minimizing software conflicts.
Please follow Apptainer install instructions for your OS before proceeding.
One may forego Apptainer by installing the packages listed in the `apptainer.def` file, however, it will not be an exact replica of the original environment used and cannot guarantee reproduction of the analysis.

### Step 1.

We can start with establishing the project structure/layout.
This can be done by first cloning/downloading this repo.
As this repo only contains source code it will be of negligible size.
The project structure currently assumes a Unix environment as there are the top-level symbolic links `data` and `results` pointing to those respective directories within `storage`.
These symbolic links may have to be recreated on non-Unix OS such as Windows.
Next, download the entire folder in the Dropbox link (see top of README) and place it at the top-level of this project.
Within this `storage` directory, one can also see all already computed results in the `results` dir.

### Step 2.

With the project structure in place, one should should make sure Apptainer is installed or attempt to install packages from `apptainer.def` manually.
Instructions for installing Apptainer for different OS can be found on their [website](https://apptainer.org/).
The image for this analysis can then be pulled by running the following in a command-line interface:

```
apptainer pull library://eturkes/acosta-organoid-scrnaseq/acosta-organoid-scrnaseq:v4
```

Once downloaded, the following command will launch an Apptainer instance of RStudio Server with access to the current project:

```
apptainer exec --bind rsession.conf:/etc/rstudio/rsession.conf,run:/run,var-lib-rstudio-server:/var/lib/rstudio-server,database.conf:/etc/rstudio/database.conf acosta-organoid-scrnaseq_v4.sif rserver --www-address=127.0.0.1 --www-port=8787
```

This will run the container on port 8787 and can be changed to any other non-used port.
One can then open a web browser and go the address `http://localhost:8787/` or whichever port was specified.

It may be preferable to supplement with additional arguments and commands, for example the line below. Please see external documentation for what these modifiers do.

```
nohup apptainer exec --bind rsession.conf:/etc/rstudio/rsession.conf,run:/run,var-lib-rstudio-server:/var/lib/rstudio-server,database.conf:/etc/rstudio/database.conf acosta-organoid-scrnaseq_v4.sif rserver --www-address=127.0.0.1 --www-port=8787 --server-user=turkes2 &
```

If one is running the analysis on a remote headless server but would like to control RStudio Server in a local web browser, an SSH tunnel can be used.
For instance the following command can be used:

```
ssh -NL 8787:localhost:8787 turkes2@owens-login03.hpc.osc.edu
```

The left-most port specifies the port desired locally, whereas the right-most is the port on the server.
The right-most argument is the user@ip-address details used to log into the server.

### Step 3.

With RStudio open in a web browser, navigate to the project directory and open the R project.
As Apptainer contains all neccessary packages at the versions of the original analysis, knitting any of the R Markdown files should reproduce the results found in the `results` dir.
Note that this overwrites the existing file in the `results` dir.
Finally, there is a `run_all.R` script that will run all the analyses in this project.
If only specific sections are of interest, sections can be easily commented out, though note that many sections are dependent on a previous section.
The dependencies are linked by a top-level `cache` folder generated by running the analysis.
