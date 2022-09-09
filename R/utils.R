#    This file is part of acosta-organoid-scRNAseq.
#    Copyright (C) 2022  Emir Turkes, Diana Acosta, Gi Guo, Yuzhou Chang,
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

# This file holds common functions and methods.

#' ggplot2 function providing custom aesthetics and automatic placement of categorical labels.
#' For continuous data, a colorbar is implemented.
#'
#' @param data SingleCellExperiment or Seurat object.
#' @param x,y Dimensionality reduction coordinates.
#' @param color Column metadata to color points by.
#' @param type \code{"cat"} is categorical, \code{"cont"} is continuous, \code{"NULL"} is generic.
#' @examples
#' red_dim_plot(data = sce, x = "tsne1", y = "tsne2", color = "cluster", type = "cat")
#' red_dim_plot(data = seurat, x = "umap1", y = "umap2", color = "nUMI", type = "cont")
#'
red_dim_plot <- function(data, x, y, color, type = NULL) {

  if ((class(data))[1] == "SingleCellExperiment") {
    gg_df <- data.frame(colData(data)[ , c(x, y, color)])
  } else if ((class(data))[1] == "Seurat") {
    gg_df <- data.frame(data[[x]], data[[y]], data[[color]])
  }
  rownames(gg_df) <- NULL
  gg_df[[color]] <- factor(gg_df[[color]])

  gg <- ggplot(gg_df, aes_string(x, y, col = color)) +
    geom_point(alpha = 0.35, stroke = 0.05, shape = 21, aes_string(fill = color)) +
    theme_classic() +
    theme(
      legend.position = "right", plot.title = element_text(hjust = 0.5),
      legend.title = element_blank()
    ) +
    guides(color = guide_legend(override.aes = list(alpha = 1)))

  if (is.null(type)) {
    return(gg)

  } else if (type == "cat") {
    label_df <- gg_df %>% group_by_at(color) %>% summarise_at(vars(x:y), median)
    label_df <- cbind(label_df[[1]], label_df)
    names(label_df) <- c("label", color, x, y)
    gg <- gg + geom_label_repel(data = label_df, aes(label = label), show.legend = FALSE)

  } else if (type == "cont") {
    if ((class(data))[1] == "SingleCellExperiment") {
      gg_df <- data.frame(colData(data)[ , c(x, y, color)])
    } else if ((class(data))[1] == "Seurat") {
      gg_df <- data.frame(data[[x]], data[[y]], data[[color]])
    }
    rownames(gg_df) <- NULL

    gg <- ggplot(gg_df, aes_string(x, y)) +
      geom_point(alpha = 0.35, stroke = 0.05, aes_string(color = color)) +
      theme_classic() +
      theme(
        legend.position = "right", plot.title = element_text(hjust = 0.5),
        legend.title = element_blank()
      ) +
      scale_color_viridis()
  }
  gg
}

#' Adds download buttons and horizontal scrolling to \code{"DT::datatable"}.
#'
#' @param dt A data.table object.
#' @examples
#' datatable_download(dt = data_table)
#'
datatable_download <- function(dt) {

  datatable(
    dt,
    list(
      scrollX = TRUE, dom = "Blfrtip",
      buttons = list(
        "copy", "print",
        list(extend = "collection", buttons = c("csv", "excel", "pdf"), text = "Download")
      )
    ),
    extensions = "Buttons"
  )
}

#' Adds download buttons, horizontal scrolling, exponential values to \code{"DT::datatable"}.
#'
#' @param dt A data.table object.
#' @examples
#' datatable_download_exp(dt = data_table)
#'
datatable_download_exp <- function(dt) {

  datatable(
    dt,
    list(
      scrollX = TRUE,
      dom = "Blfrtip",
      buttons = list(
        "copy", "print",
        list(extend = "collection", buttons = c("csv", "excel", "pdf"), text = "Download")
      ),
      rowCallback = JS(
        "function(row, data) {",
        "for (i = 1; i < data.length; i++) {",
        "if (data[i]>=1000 | data[i]<1000) {",
        "$('td:eq('+i+')', row).html(data[i].toExponential(2));}}}"
      )
    ),
    extensions = "Buttons"
  )
}

#' Pipeline for normalization, dimensionality reduction, and clustering of post-QC scRNA-seq data.
#'
#' @param seurat Post-QC Seurat object.
#' @param cache_dir Directory to save post-processed Seurat object.
#' @param sub_name Subset level for naming of cache object.
#' @param protocol Vector with the following elements in this order: \code{"human"} or
#' \code{"mouse"}. \code{"droplet"} or \code{"smart-seq"}. \code{"single-cell"} or
#' \code{"single-nuc"}. \code{"umis"} or \code{"reads"}.
#' @param vars_to_regress Vector of nuisance variables for sctransform to regress out.
#' @param parallel_override See function \code{"parallel_plan"}.
#' @param cc Logical, whether to perform cell-cycle scoring.
#' @examples
#' cluster_pipeline(
#'   seurat = seurat, cache_dir = cache_dir, sub_name = "neuronal", protocol = protocol,
#'   vars_to_regress = "mito_percent", parallel_override = NULL, cc = FALSE)
#' )
cluster_pipeline <- function(
  seurat, cache_dir, sub_name, protocol, vars_to_regress, parallel_override, cc = TRUE
) {

  rds <- file.path(cache_dir, paste0(sub_name, "_seurat.rds"))
  if (file.exists(rds)) {
    seurat <- readRDS(rds)
    return(seurat)
  } else {

    if (protocol[4] == "umis") {
      # Run sctransform.
      # Note that this function produces many iterations of the following benign warning:
      # Warning in theta.ml(y = y, mu = fit$fitted): iteration limit reached
      # ---------------------------------------------------------------------------------
      parallel_plan(seurat, parallel_override)
      seurat <- suppressWarnings(
        SCTransform(
          seurat, vars.to.regress = vars_to_regress, vst.flavor = "v2",
          return.only.var.genes = FALSE, verbose = FALSE
        )
      )
      # ---------------------------------------------------------------------------------

      # Perform PCA.
      # ------------
      seurat <- RunPCA(seurat, features = rownames(seurat), verbose = FALSE)
      add_df <- data.frame(Embeddings(seurat)[ , 1:2])
      names(add_df) <- paste0("pca", seq(ncol(add_df)))
      seurat$pca1 <- add_df$pca1
      seurat$pca2 <- add_df$pca2
      reduction <- "pca"
      dims <- 1:30 # Dimensions for downstream computations.
      # ------------

    } else if (protocol[4] == "reads") {
      sce <- as.SingleCellExperiment(seurat) # ZINB-WaVE can directly take an SCE but not Seurat.
      logcounts(sce) <- NULL

      # Use top 1,000 variable features for downstream computations.
      # ------------------------------------------------------------
      seurat <- NormalizeData(seurat, verbose = FALSE)
      seurat <- FindVariableFeatures(seurat, nfeatures = 1000, verbose = FALSE)
      sce <- sce[rownames(sce) %in% VariableFeatures(seurat), ]
      # ------------------------------------------------------------

      # Get ENSEMBL annotations for more accurate retrieval of gene length and GC content.
      # ----------------------------------------------------------------------------------
      if (protocol[1] == "human") {
        dataset <- "hsapiens_gene_ensembl"
      } else if (protocol[1] == "mouse") {
        dataset <- "mmusculus_gene_ensembl"
      }
      mart <- useEnsembl("ensembl", dataset)
      attributes <- c("external_gene_name", "ensembl_gene_id")
      gene_anno <- getBM(attributes, "external_gene_name", rownames(sce), mart)
      # ----------------------------------------------------------------------------------

      # For gene symbols with multiple ENSEMBL IDs, duplicate the gene symbol to have an identical
      # row for each ENSEMBL ID.
      # ------------------------------------------------------------------------------------------
      dup <- gene_anno[duplicated(gene_anno$external_gene_name), ]
      for (i in 1:dim(dup)[1]) {
        for (j in 1:dim(gene_anno)[1]) {
          if (dup$ensembl_gene_id[i] == gene_anno$ensembl_gene_id[j]) {
            gene_anno$external_gene_name[j] <- paste0(gene_anno$external_gene_name[j], "-dup")
          }
        }
      }
      sce <- sce[rownames(sce) %in% gene_anno$external_gene_name, ]
      new_mat <- counts(sce)
      for (i in 1:dim(dup)[1]) {
        for (j in 1:dim(sce)[1]) {
          if (dup$external_gene_name[i] == rownames(sce)[j]) {
            new_row <- t(counts(sce)[j, ])
            rownames(new_row) <- paste0(rownames(counts(sce))[j], "-dup")
            new_mat <- rbind(new_mat, new_row)
          }
        }
      }
      gene_anno <- gene_anno[gene_anno$external_gene_name %in% rownames(new_mat), ]
      gene_anno <- gene_anno[order(match(gene_anno$external_gene_name, rownames(new_mat))), ]
      rownames(new_mat) <- gene_anno$ensembl_gene_id
      sce <- SingleCellExperiment(list(counts = new_mat), colData = colData(sce))
      # ------------------------------------------------------------------------------------------

      # Get gene lengths and GC content.
      # --------------------------------
      row_data <- data.frame(getGeneLengthAndGCContent(rownames(sce), dataset, "biomart"))
      rowData(sce) <- data.frame(gc_content = row_data$gc, length = row_data$length)
      # --------------------------------

      # Run ZINB-WaVE.
      # TODO: Fix hardcoding of `vars_to_regress`.
      # ------------------------------------------
      counts(sce) <- as.matrix(counts(sce)) # ZINB-WaVE is incompatible with dgCMatrix.
      sce <- zinbwave(
        sce, paste0("~ ", vars_to_regress[1], " + ", vars_to_regress[2]), "~ gc_content + length",
        10, epsilon = 1e12, BPPARAM = MulticoreParam()
      )

      zinb <- data.frame(reducedDim(sce, "zinbwave"))
      seurat$zinb1 <- zinb$W1
      seurat$zinb2 <- zinb$W2
      zinb <- as.matrix(zinb)
      seurat[["zinb"]] <- CreateDimReducObject(zinb, key = "W", assay = DefaultAssay(seurat))
      reduction <- "zinb"
      dims <- 1:10 # Dimensions for downstream computations.
      # ------------------------------------------
    }

    # Perform cell cycle scoring.
    # ---------------------------
    if (cc == TRUE) {
      if (protocol[1] == "human") {
        s_genes <- cc.genes.updated.2019$s.genes
        g2m_genes <- cc.genes.updated.2019$g2m.genes
      } else if (protocol[1] == "mouse") {
        s_genes <- human_to_mouse_genes(cc.genes.updated.2019$s.genes)
        g2m_genes <- human_to_mouse_genes(cc.genes.updated.2019$g2m.genes)
      }
      seurat <- CellCycleScoring(seurat, s_genes, g2m_genes)
      seurat$cc_diff <- seurat$S.Score - seurat$G2M.Score # Combined proliferating cell signal.
    }
    # ---------------------------

    # Perform UMAP reduction.
    # -----------------------
    seurat <- RunUMAP(seurat, dims, reduction, verbose = FALSE)
    add_df <- data.frame(Embeddings(seurat, "umap"))
    names(add_df) <- paste0("umap", seq(ncol(add_df)))
    seurat$umap1 <- add_df$umap1
    seurat$umap2 <- add_df$umap2
    # -----------------------

    # Perform Louvain clustering.
    # ---------------------------
    resolution <- (dim(seurat)[2] / 3000) * 0.8 # Default is optimal for 3K cells so we scale it.
    seurat <- FindNeighbors(seurat, reduction, dims, verbose = FALSE)
    seurat <- FindClusters(seurat, resolution = resolution, verbose = FALSE)
    # ---------------------------

    saveRDS(seurat, rds, compress = FALSE)
  }
  seurat
}

#' Set the \code{"plan"} for \code{"future"} based on free memory and object size with the option to
#' override.
#'
#' @param object Object to check if \code{"future.globals.maxSize"} large enough to parallelize.
#' @param parallel_override \code{"NULL"} to calculate plan decision, \code{0} for sequential, a
#' non-zero integer for multiprocess and to set \code{"future.globals.maxSize"}.
#' @examples
#' parallel_plan(object = seurat, parallel_override = 5368709120)
#'
parallel_plan <- function(object, parallel_override = NULL) {

  if (is.null(parallel_override)) {
    # Get free memory.
    # ----------------
    gc()
    mem <- as.numeric(unlist(strsplit(system("free -b", TRUE)[2], " "))[7])
    # ----------------

    # Distribute free memory (minus 10 GiB) across available cores.
    # -------------------------------------------------------------
    mem <- mem - 10 * 1024 ^ 3
    mem <- mem / detectCores()
    # -------------------------------------------------------------

    # Enable parallelization only if `object` can fit in `future.globals.maxSize` (plus 1 Gib).
    # -----------------------------------------------------------------------------------------
    if (mem > object.size(object) + 1 * 1024 ^ 3) {
      plan("multiprocess")
      options(future.globals.maxSize = mem)
    } else {
      plan("sequential")
    }
    # -----------------------------------------------------------------------------------------

  } else if (parallel_override == 0) {
    plan("sequential")

  } else {
    plan("multiprocess")
    options(future.globals.maxSize = parallel_override)
  }
}


#' Plot genes of a Seurat object in various ways.
#'
#' @param subset_list A list containing Seurat objects.
#' @param subset_names A character vector of names for each Seurat object.
#' @param genes A character vector of genes to plot.
#' @examples
#' gene_plot(subset_list = sublist, subset_names = c("seurat1, "seurat2"), genes = c("TBR1, "GAD1))
#'
gene_plot <- function(subset_list, subset_names, genes) {

  for (i in 1:length(subset_list)) {

    if (length(which(genes %in% rownames(subset_list[[i]]))) > 4) {
      ncol <- 3
    } else {
      ncol <- 2
    }

    if (length(genes) == 2 && all(genes %in% rownames(subset_list[[i]]))) {
      plots <- FeaturePlot(
        subset_list[[i]], genes, order = TRUE, blend = TRUE,
        combine = FALSE, blend.threshold = 0, max.cutoff = "q10", reduction = "umap"
      )
      print(CombinePlots(plots[3:4], legend = "none") + NoLegend())
    } else if (any(genes %in% rownames(subset_list[[i]]))) {
      print(
        FeaturePlot(
          subset_list[[i]], genes, order = TRUE, cols = c("lightgrey", "red"),
          ncol = ncol, keep.scale = "all", reduction = "umap"
        )
      )
    }

    if (any(genes %in% rownames(subset_list[[i]]))) {
      print(DotPlot(subset_list[[i]], features = genes, cols = c("blue", "red")) + RotatedAxis())
      print(
        DoHeatmap(subset_list[[i]], genes, slot = "data", size = 3) +
          NoLegend() +
          scale_fill_gradient2(
            low = rev(c('#D1E5F0','#67A9CF','#2166AC')), mid = "white",
            high = rev(c('#B2182B','#EF8A62','#FDDBC7')), midpoint = 0,
            guide = "colourbar", aesthetics = "fill"
          )
      )
      print(VlnPlot(subset_list[[i]], genes, ncol = ncol - 1))
    }
  }
}

computeGeneSetsOverlapMax <- function(gSets, uniqGenes, min.sz=1, max.sz=Inf) {
  ## gSetsMembershipMatrix should be a (genes x gene-sets) incidence matrix

  gSetsMembershipMatrix <- incidence(gSets)
  gSetsMembershipMatrix <- t(gSetsMembershipMatrix[, colnames(gSetsMembershipMatrix) %in% uniqGenes])

  lenGsets <- colSums(gSetsMembershipMatrix)

  szFilterMask <- lenGsets >= max(1, min.sz) & lenGsets <= max.sz
  if (!any(szFilterMask))
    stop("No gene set meets the minimum and maximum size filter\n")

  gSetsMembershipMatrix <- gSetsMembershipMatrix[, szFilterMask]
  lenGsets <- lenGsets[szFilterMask]

  totalGsets <- ncol(gSetsMembershipMatrix)

  M <- t(gSetsMembershipMatrix) %*% gSetsMembershipMatrix

  M1 <- matrix(lenGsets, nrow=totalGsets, ncol=totalGsets,
               dimnames=list(colnames(gSetsMembershipMatrix), colnames(gSetsMembershipMatrix)))
  M2 <- t(M1)
  M.max <- matrix(0, nrow=totalGsets, ncol=totalGsets)
  M.max[M1 > M2] <- M1[M1 > M2]
  M.max[M2 >= M1] <- M2[M2 >= M1]
  overlapMatrix <- M / M.max

  return (overlapMatrix)
}
