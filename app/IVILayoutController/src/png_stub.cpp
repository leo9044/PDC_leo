/**
 * Dummy implementation for missing save_as_png function
 * ILM library references this but doesn't provide it
 */

extern "C" {
    int save_as_png(const char*, int, int, unsigned char*, int) {
        // Not needed for our layout controller
        return 0;
    }
}
