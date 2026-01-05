## Setting Up R for Jupyter Notebooks
This project includes R notebooks (R_MEMs_*.ipynb) that require additional setup to run R code in Jupyter:

1. **Install R**:
   - Download and install R from [CRAN](https://cran.r-project.org/)

2. **Install the R extension for VS Code**:
   - Open VS Code
   - Go to the Extensions view
   - Install "R" by REditorSupport
   - The extension will provide additional instructions and setup guidance upon installation

3. **Install the R kernel for Jupyter** (IRkernel):
   
   Open R and run:
   ```r
   install.packages('IRkernel')
   IRkernel::installspec(user = TRUE)
   ```
4. **Verify R kernel installation**:
   
   After installation, restart VS Code. When you open an R notebook (e.g., `R_MEMs_Combined.ipynb`), you should see "R" as an available kernel option in the kernel selector (top-right of the notebook).

5. **Select the R kernel**:
   - Open any R notebook
   - Click on the kernel selector in the top-right corner
   - Choose "R" from the list of available kernels

**Troubleshooting**:
- If the R kernel doesn't appear, try restarting VS Code
- Ensure R is added to your system PATH
- On Windows, you may need to run VS Code as administrator when first setting up IRkernel