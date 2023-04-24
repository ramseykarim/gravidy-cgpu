# Makefile
CUDA_PATH=/cvmfs/hpcsw.umd.edu/spack-software/2022.06.15/linux-rhel8-zen/gcc-8.4.0/cuda-10.2.89-omyaqz6mv6t3fihltamr67fnj5xij5an
MPI_LIB_PATH=$(OPENMPI_LIBDIR)
MPI_INC_PATH=$(OPENMPI_INCDIR)

# Compilers
CXX=  g++
NVCC= nvcc

# FLAGS

# Boost FLAGS
#BOOSTFLAGS  = -L$(BOOST_PATH)/lib
#BOOSTFLAGS += -I$(BOOST_PATH)/include
BOOSTFLAGS  = -L$(BOOST_LIBDIR)
BOOSTFLAGS += -I$(BOOST_INCDIR)
BOOSTFLAGS += -lboost_program_options

# Links FLAGS
LINKFLAGS  = -L$(CUDA_PATH)/lib64
LINKFLAGS += -I$(CUDA_PATH)/include
LINKFLAGS += -lcuda
LINKFLAGS += -lcudart
LINKFLAGS += -DGPU

# C++ FLAGS
CXXFLAGS  = $(BOOSTFLAGS)
#CXXFLAGS += -std=c++11 -D_GLIBCXX_USE_CXX11_ABI=0 # For gcc > 5.2.1, by CCH on 2023-04-23
CXXFLAGS += -std=c++11 # by CCH on 2023-04-23
CXXFLAGS += -O3 # Optimisation
CXXFLAGS += -Wall # Warning messages
CXXFLAGS += -fopenmp # Enable OpenMP
CXXFLAGS += -pipe # Pipes over temp files in the process
CXXFLAGS += -fstack-protector # Emit extra code to check buffer overflow
CXXFLAGS += -Wl,-z,relro # RO relocation table area in the final ELF
CXXFLAGS += -Wl,-z,now # Prevent GOT overwrite attacks
CXXFLAGS += -Wformat-security # Prevent formats vulnerabilities
CXXFLAGS += -Wpointer-arith # Prevent void size
CXXFLAGS += -Wformat-nonliteral # Prevent non literal format string
CXXFLAGS += -Wl,-O1 # Optimisation for the linker
CXXFLAGS += -Wl,--discard-all # Discard local symbols
CXXFLAGS += -Wl,--no-undefined # Prevent missing/unresolved symbols
CXXFLAGS += -rdynamic # Exported symbols in dynamics symbol table
#CXXFLAGS += -pg # For gprof
#CXXFLAGS += -Werror # Warnings will be errors

# MPI FLAGS
MPIFLAGS  = -L$(MPI_LIB_PATH)
MPIFLAGS += -I$(MPI_INC_PATH)
MPIFLAGS += -pthread
MPIFLAGS += -lmpi
MPIFLAGS += -lmpi_cxx
MPIFLAGS += -ldl
MPIFLAGS += -D_MPI
MPIFLAGS += -DOMPI_SKIP_MPICXX

# CUDA FLAGS
NVFLAGS  = -DGPU
NVFLAGS += -pg
NVFLAGS += -O3
#NVFLAGS=-std=c++11 -arch=sm_20 # -DBOOST_NOINLINE='__attribute__ ((noinline))'
#NVFLAGS=-std=c++11 -arch=sm_20 -D_MWAITXINTRIN_H_INCLUDED # For gcc > 5.2.1

# General Objects
OBJS  = include/utils/OptionsParser.o
OBJS += include/utils/NbodyUtils.o
OBJS += include/utils/Logger.o
OBJS += include/Hermite4.o
OBJS += include/NbodySystem.o

# CPU objects
OBJS_CPU  = $(OBJS)
OBJS_CPU += include/cpu/Hermite4CPU_integration.o
OBJS_CPU += include/cpu/Hermite4CPU.o

# MPI objects
OBJS_MPI  = $(OBJS)
OBJS_MPI += include/mpi/Hermite4MPI_integration.o
OBJS_MPI += include/mpi/Hermite4MPI.o
OBJS_MPI += include/mpi/MPIUtils.o

# GPU objects
OBJS_GPU  = $(OBJS)
OBJS_GPU += include/gpu/Hermite4GPU_kernels.cuo
OBJS_GPU += include/gpu/Hermite4GPU_integration.o
OBJS_GPU += include/gpu/Hermite4GPU.cuo

# Main rules
.PHONY: cpu pn mpi gpu doxy clean distclean

all: cpu

pn: print_pn
pn: gravidy-cpu

cpu: gravidy-cpu

mpi: CXXFLAGS+=$(MPIFLAGS)
mpi: gravidy-mpi

gpu: CXXFLAGS+=$(LINKFLAGS)
gpu: gravidy-gpu

print_pn:
	@echo "PN implementation is enabled in CPU version"

# Rules to generate CUDA object
%.cuo : %.cu
	$(NVCC) $(BOOSTFLAGS) $(NVFLAGS) -c $^ -o $@

# Rules to generate binaries
gravidy: gravidy.cpp
	$(CXX) $^ -o $@ $(CXXFLAGS)

gravidy-cpu: gravidy.cpp $(OBJS_CPU)
	$(CXX) $^ -o $@ $(CXXFLAGS)

gravidy-mpi: gravidy.cpp $(OBJS_MPI)
	$(CXX) $^ -o $@ $(CXXFLAGS)

gravidy-gpu: gravidy.cpp $(OBJS_GPU)
	$(CXX) $^ -o $@ $(CXXFLAGS)

# Generate documentation
doxy:
	@doxygen -s Doxyfile

# Clean
clean:
	rm -f gravidy
	rm -f gravidy-gpu
	rm -f gravidy-cpu
	rm -f gravidy-mpi

distclean: clean
	rm -f include/*.o
	rm -f include/cpu/*.o
	rm -f include/utils/*.o
	rm -f include/gpu/*.{o,cuo}
	rm -f include/mpi/*.o
	rm -f gmon.out
