# Setup

There are two options to create the Docker container:
  * An image is available via Docker Hub: `docker pull fdeconinck/sc22_daint:latest` (or `sarus pull` on Piz Daint)
  * The Dockerfile and all associated scripts can be built from the files in this repository. Use the following command: `docker build -t <some tag> -f ./artifact.Dockerfile .`
  

# Running 

To run the workload, at least 6 ranks (each with its own GPU) are necessary. Each rank will start up its own container, as shown in the following example using the SLURM job scheduler:
```
srun -N 6 docker run fdeconinck/sc22_daint:latest bash /runner.sh
```

or, if on Piz Daint (where the container was tested), Sarus can be used to connect the container to the native MPI implementation and GPU:
```
module load sarus
srun -N 6 sarus run --mpi fdeconinck/sc22_daint:latest bash /runner.sh
```

The script (`runner.sh`) runs in two phases: Build (which will compile the SDFG to execute) and Run (which will run the code for performance). The two can be split to be built and run separately, but it is beneficial to compile the code on the target architecture for improved performance. To split building and running, only run the first two (Build) or last two (Run) of the four final commands in the script. 

In order to run the baseline FORTRAN version, refer to the README in https://github.com/ai2cm/fv3gfs-fortran/tree/9030cf9c9241d087e8fcdef71ab9458aee980609
The benchmark input folders provided here are compatible with the FORTRAN version.


# File structure

* `c*_*ranks_baroclinic`: Folders containing benchmark inputs for the given number of ranks
* `artifact.Dockerfile`: Docker container setup script
* `c576_54ranks_A100.log`: Log file containing the output of the 54-GPU run on NVIDIA A100 GPUs
* `daint_logs.tar.xz`: A zip file containing all logs from the scaling experiments on Piz Daint
* `plotting.py`: Plots the scaling figure from the paper (uses `data.csv` from `daint_logs.tar.xz`)
* `README.md`: This file
* `runner.sh`: Run script used in Docker container
