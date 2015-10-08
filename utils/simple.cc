#include <windows.h>                      
#include <stdio.h>
#include <tchar.h>
//# define PSAPI_VERSION 2
#include <psapi.h>

void _tmain (int argc, TCHAR *argv[])
{
    // use first argument as PID
    DWORD processID = strtol(argv[1],0, 0);
    HANDLE hProcess = OpenProcess(
           PROCESS_QUERY_INFORMATION | PROCESS_VM_READ | SYNCHRONIZE,
           FALSE,
           processID);
    PROCESS_MEMORY_COUNTERS_EX pmc;
    ZeroMemory(&pmc, sizeof(PROCESS_MEMORY_COUNTERS_EX));
    // wait until process is dead
    WaitForSingleObject( hProcess , INFINITE);

    GetProcessMemoryInfo( hProcess, (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc) );
    fprintf(stdout, "  PeakWorkingSetSize : %d\n", pmc.PeakWorkingSetSize);
    fprintf(stdout, "  PrivateUsage : %d\n", pmc.PrivateUsage);
    CloseHandle(hProcess);
}
