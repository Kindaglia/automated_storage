# Developer Documentation

This guide is intended for developers who wish to contribute to, modify, or extend the `automated_chest` mod.

## Code Structure

The mod is organized into modular files for better maintainability:

*   **`init.lua`**: The entry point. Sets up the global `automated_chest` namespace and loads the other modules.
*   **`functions.lua`**: Contains core logic, including:
    *   Inventory management (detached inventories for filtering).
    *   Filtering logic (`get_filtered_items`).
    *   Sorting logic (`sort_inventory`).
    *   Player state management (`player_search_state`).
*   **`gui.lua`**: Handles the UI:
    *   Formspec generation (`show_chest_formspec`).
    *   Event handling (`on_player_receive_fields`).
*   **`nodes.lua`**: Defines the chest node (`automated_chest:chest`) and its LBMs (Loading Block Modifiers) for upgrades.
*   **`crafting.lua`**: Registers crafting recipes.

## Key Concepts

### Infinite Storage / Large Inventory
The chest uses a standard Minetest inventory size set to 1000 slots. While not truly "infinite", this is large enough to require custom UI handling.
*   **Performance:** Displaying 1000 slots at once would lag the client.
*   **Solution:** We use a **Scroll Container** in the Formspec to show only a window of the inventory at a time. The Formspec dynamically calculates the total size of the scrollable area based on the inventory content.

### Search and Filtering
Filtering is achieved using **Detached Inventories**.
1.  When a user types a query, `get_filtered_items` scans the real node inventory.
2.  Matching items are copied to a temporary detached inventory unique to that player (`automated_chest_filter_<playername>`).
3.  The Formspec is updated to display this detached inventory instead of the node's inventory.
4.  **Interaction:** Callbacks in `init_player_detached_inv` intercept `on_take` and `on_put` events in the detached inventory and proxy them to the real node inventory, ensuring data consistency.

### Sorting
The sorting function (`sort_inventory` in `functions.lua`):
1.  Removes all items from the chest.
2.  Sorts them by name (and then by count).
3.  Re-adds them to the chest. Minetest's `add_item` automatically handles stacking.

## Formspec Details

The UI is built using `formspec_version[4]`.
*   **Dependencies:** Uses `mcl_formspec` for consistent theming with Mineclonia (backgrounds, slots).
*   **Dynamic Sizing:** The number of rows in the scroll container is calculated dynamically: `math.ceil(inv_size / 9)`.

## Extensibility

### Adding New Features
1.  **Logic:** Add the function to `functions.lua`. Add it to the `automated_chest` global table.
2.  **UI:** Update `gui.lua` to add the button or widget.
3.  **Events:** Handle the event in `register_on_player_receive_fields` in `gui.lua`.

### Changing Capacity
To change the capacity:
1.  Update `inv:set_size` in `nodes.lua` (`on_construct`).
2.  Add a new LBM in `nodes.lua` to migrate existing chests.
3.  Update documentation.

## Testing

*   **LBMs:** When changing inventory sizes, always test with an existing chest from a previous version to ensure items are preserved and the size is updated.
*   **Detached Inventory:** Test edge cases in filtering (e.g., taking the last item of a stack, adding items when the chest is full).

## Style Guide

*   Use `local` variables wherever possible.
*   Expose public functions via the `automated_chest` table.
*   Follow standard Lua formatting (4 spaces indentation).
