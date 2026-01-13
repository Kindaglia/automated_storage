# Automated Chest

**Automated Chest** is a Mineclonia-compatible mod that adds a high-capacity storage block with advanced inventory management features.

![Automated Chest Interface](https://github.com/Kindaglia/automated_storage/blob/main/textures/automated_storage_front.png)

## Features

- **Massive Storage:** 1000 slots of storage space in a single block.
- **Integrated Search:** Built-in search bar to filter and find items within the chest.
- **Scrollable Interface:** Custom UI with a scrollbar to easily navigate the large inventory without cluttering the screen.
- **Smart Filtering:** 
  - Items can be withdrawn directly from the filtered view.
  - Adding items in filtered view attempts to place them into the chest's main inventory.
- **Mineclonia Integration:** Fully compatible with `mcl_core`, `mcl_formspec`, and `mcl_sounds`.

## Screenshots

![Example 1](https://github.com/Kindaglia/automated_storage/blob/main/img/example01.png)
![Example 2](https://github.com/Kindaglia/automated_storage/blob/main/img/example02.png)
![Example 3](https://github.com/Kindaglia/automated_storage/blob/main/img/example03.png)
![Example 4](https://github.com/Kindaglia/automated_storage/blob/main/img/example04.png)
![Example 5](https://github.com/Kindaglia/automated_storage/blob/main/img/example05.png)

## Technical Details

- **Node Name:** `automated_chest:chest`
- **Dependencies:** `mcl_core`, `mcl_formspec`, `mcl_sounds`
- **Groups:** `pickaxey=1`, `container=2`, `material_wood=1`, `flammable=1`, `axey=1`

## Crafting

The Automated Chest is crafted using a standard chest surrounded by wood.

```
[ Wood ] [ Wood ] [ Wood ]
[ Wood ] [ Chest] [ Wood ]
[ Wood ] [ Wood ] [ Wood ]
```

- **Center:** `mcl_chests:chest` (Standard Chest)
- **Surround:** `group:wood` (Any wood planks)

## Usage

1. **Place** the Automated Chest.
2. **Right-click** to open the interface.
3. **Store Items:** Drag and drop items into the scrollable grid.
4. **Search:** Type in the search bar at the top right and press Enter to filter items by name or description.
   - The view will update to show only matching items.
   - You can take items directly from the search results.
5. **Sort:** Click the "Sort" button to automatically stack and alphabetize the items in the chest.

## Configuration

The mod includes an LBM (Loading Block Modifier) that automatically upgrades older versions of the chest to the latest capacity upon loading the area.

## Development

For information on the code structure and how to extend this mod, see [DEVELOPMENT](https://github.com/Kindaglia/automated_storage/blob/main/DEVELOPMENT.md).

## Author

- **Kindaglia** - [https://github.com/Kindaglia](https://github.com/Kindaglia)

