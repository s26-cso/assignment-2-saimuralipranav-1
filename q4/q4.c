#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>

typedef int (*op_fn_t)(int, int);

int main(void)
{
    char line[128];     // buffer to read each line
    char op[6];         // operation name (max 5 chars)
    int num1, num2;

    // Read input line-by-line until EOF
    while (fgets(line, sizeof(line), stdin))
    {
        // Try to parse: op num1 num2
        // If format is wrong → skip this line
        if (sscanf(line, "%5s %d %d", op, &num1, &num2) != 3)
            continue;

        // Build library name: "./lib<op>.so"
        char lib_path[32];
        snprintf(lib_path, sizeof(lib_path), "./lib%s.so", op);

        // Load the shared library
        void *handle = dlopen(lib_path, RTLD_LAZY);
        if (!handle)
            continue;   // if library not found → skip

        // Get function with same name as operation
        op_fn_t fn = (op_fn_t)dlsym(handle, op);
        if (!fn)
        {
            dlclose(handle);
            continue;   // if function missing → skip
        }

        // Call function and print result
        printf("%d\n", fn(num1, num2));

        // Free library after use (keeps memory low)
        dlclose(handle);
    }

    return 0;
}