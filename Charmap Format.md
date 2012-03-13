The charmap file is used to map character codes to virtual key codes. Each character or key code is represented as an 8 bit number. If a character code does not map to a key code, the special value 255 is used.

The file should generally only contain mappings for characters which can be typed without modifiers. If other characters are included and the user attempts to use them, they will work without the modifiers needed to create them. Note that this can only occur if the user defines the mapping in a different keyboard layout than the current, or modifies the preference file manually. The table should also usually not contain mappings for standard whitespace and control characters, as their key codes are not layout-dependent. If they are included, they will override the default.

The first 26 characters in the file are the key codes for the lowercase Latin alphabet, in alphabetic order. The next 10 are the key codes for the decimal digits 0-9.

Characters not in these sets are mapped using a table which maps character ranges to entries in an array. The first byte indicates the number of ranges, and the second indicates the total length of the array. The data immediately after these bytes represents the character ranges, which should be listed in order of increasing array offset.

Each character range is represented by three bytes. The first two are the first and last characters in the range, and the third is the 0-indexed offset into the array of the key code for the first character. Ranges may overlap in the array, which may be useful if two nearby ranges are separated only by characters with no key code, since the ranges can be combined and the extra array positions used by another short range. This could cause an issue if the separating characters can be created using modifiers, as described above.

The remaining data in the file is an array of key codes, referenced by the character ranges. The total size of the file should exactly match the number of bytes required, as indicated by the range and array size bytes. Specifically, the structures used by the code are:

    struct CharMap_Table {
        char start; // inclusive
        char end; // inclusive
        UInt8 mapOffset;
    } __attribute__((__packed__));
    struct CharMap {
        UInt8 letters[26];
        UInt8 numbers[10];
        UInt8 tableCount;
        UInt8 mapCount;
        struct CharMap_Table table[0];
        UInt8 map[0];
    } __attribute__((__packed__));

and the size must match this value:

    sizeof(struct CharMap) +
        tableCount * sizeof(struct CharMap_Table) +
        mapCount * sizeof(UInt8)
