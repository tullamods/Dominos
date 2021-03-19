# Dominos (The API)

As of Dominos 8.4, I've started implementing callbacks into the addon.

## Global Callbacks

### LAYOUT_LOADING

Called before a new Dominos layout is loaded

### LAYOUT_LOADED

Called after a new Dominos layout is loaded

### BINDING_MODE_ENABLED

Called after binding mode is enabled

### BINDING_MODE_DISABLED

Called after binding mode is diabled

### OPTIONS_MENU_LOADING

Called when the options menu starts loading

### OPTIONS_MENU_LOADED

Called when the options menu finishes loading

### ALIGNMENT_GRID_ENABLED (enable)

Called when the alignment grid is enabled or disabled

### ALIGNMENT_GRID_SIZE_CHANGED (size)

Called when the alignment grid size is changed


## Bar Callbacks

### BAR_DISPLAY_LAYER_UPDATED (bar, id, layer)

Called when a bar's frame strata changes

### BAR_DISPLAY_LEVEL_UPDATED (bar, id, level)

Called when a bar's frame level changes