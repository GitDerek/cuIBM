#include <solvers/NavierStokes/TairaColoniusSolver.h>
#include <sys/stat.h>

template <typename memoryType>
void TairaColoniusSolver<memoryType>::updateBodies()
{
}

template <typename memoryType>
void TairaColoniusSolver<memoryType>::initialise()
{	
	int nx = NavierStokesSolver<memoryType>::domInfo->nx,
        ny = NavierStokesSolver<memoryType>::domInfo->ny;
	
	int numUV = (nx-1)*ny + nx*(ny-1);
	int numP  = nx*ny;
	
	initialiseBodies();
	std::cout << "Initialised bodies!" << std::endl;
	
	printf("NS initalising\n");
	
	parameterDB &db = *NavierStokesSolver<memoryType>::paramDB;
	
	NavierStokesSolver<memoryType>::timeStep = db["simulation"]["startStep"].get<int>();
			
	// create directory
	std::string folderName = db["inputs"]["folderName"].get<std::string>();
	mkdir(folderName.c_str(), S_IRWXU | S_IRWXG | S_IROTH | S_IXOTH);
	
	// write grid data to file
	io::writeGrid(folderName, *NavierStokesSolver<memoryType>::domInfo);
	
	NavierStokesSolver<memoryType>::initialiseArrays(numUV, numP+2*B.totalPoints);
	
	NavierStokesSolver<memoryType>::assembleMatrices();
	std::cout << "Assembled matrices!" << std::endl;
}

template <typename memoryType>
void TairaColoniusSolver<memoryType>::updateSolverState()
{
	NavierStokesSolver<memoryType>::updateBoundaryConditions();
	if (B.bodiesMove) {
		updateBodies();
		updateQT();
		NavierStokesSolver<memoryType>::generateC();
	}
}

template <typename memoryType>
void TairaColoniusSolver<memoryType>::calculateForce()
{
	int  nx = NavierStokesSolver<memoryType>::domInfo->nx,
	     ny = NavierStokesSolver<memoryType>::domInfo->ny;
	
	array1d<real, memoryType>
		f(2*B.totalPoints),
		F((nx-1)*ny + nx*(ny-1));
	
	real dx = NavierStokesSolver<memoryType>::domInfo->dx[ B.I[0] ],
	     dy = dx;
	
	thrust::copy(NavierStokesSolver<memoryType>::lambda.begin() + nx*ny, NavierStokesSolver<memoryType>::lambda.end(), f.begin());
	cusp::multiply(ET, f, F);
	NavierStokesSolver<memoryType>::forceX = (dx*dy)/dx*thrust::reduce( F.begin(), F.begin()+(nx-1)*ny );
	NavierStokesSolver<memoryType>::forceY = (dx*dy)/dy*thrust::reduce( F.begin()+(nx-1)*ny, F.end() );
}

#include "TairaColonius/generateQT.inl"
#include "TairaColonius/generateBC2.inl"
#include "TairaColonius/initialiseBodies.inl"

template class TairaColoniusSolver<host_memory>;
template class TairaColoniusSolver<device_memory>;
