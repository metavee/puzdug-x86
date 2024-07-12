import random

# init map
level = [
    c
    for c in """
...W................
...WW.WWWWW.W.......
.......W....W.......
...WW..W..W.W.......
.......WW.W.W.......
..........W.W.......
W.WWWWWWWWW.........
..W.................
..W.................
..W.................
..W.................
....................
....................
....................
....................
....................
....................
....................
....................
....................
""".replace(
        "\n", ""
    )
]

fog = [True for _ in level]
dfs_buffer = []
def reset_dfs_buffer():
    dfs_buffer.clear()
    for _ in level:
        dfs_buffer.append(False)

VISION_RADIUS = 2

LEVEL_DIM = 20
LEVEL_SIZE = LEVEL_DIM * LEVEL_DIM
assert len(level) == LEVEL_SIZE


def pos2coord(pos):
    return (pos % LEVEL_DIM, pos // LEVEL_DIM)


def coord2pos(x, y):
    return y * LEVEL_DIM + x


# init player
while True:
    PLAYER_POS = random.randrange(LEVEL_SIZE)
    if level[PLAYER_POS] == ".":
        break


def display_level():
    print()
    for i in range(LEVEL_SIZE):
        if i == PLAYER_POS:
            print("@", end=" ")
        else:
            if (fog[i]):
                print("~", end=" ")
            else: 
                print(level[i], end=" ")

        if (i + 1) % LEVEL_DIM == 0:
            print()

    print()
    print(pos2coord(PLAYER_POS))


# figure out new pos
# forbid new pos if <0, >level, is wall, wraps row


def handle_direction(key):
    global PLAYER_POS
    coords = list(pos2coord(PLAYER_POS))

    if key == "a":
        axis = 0
        direction = -1
    elif key == "d":
        axis = 0
        direction = 1
    elif key == "w":
        axis = 1
        direction = -1
    elif key == "s":
        axis = 1
        direction = 1
    else:
        raise RuntimeError(f"Got unexpected key {key}")

    coords[axis] += direction

    if coords[axis] < 0 or coords[axis] >= LEVEL_DIM:
        print("Hit edge of level")
        return

    new_pos = coord2pos(*coords)
    if level[new_pos] == "W":
        print("Hit wall")
        return

    PLAYER_POS = new_pos
    check_vision(*coords, VISION_RADIUS)


def handle_input(key: str):
    key = key.lower()
    if len(key) == 1 and key in "wasd":
        handle_direction(key)
    else:
        print(f"Unknown input `{key}`\n")


def check_vision(x, y, radius):
    if x < 0 or x >= LEVEL_DIM:
        return
    if y < 0 or y >= LEVEL_DIM:
        return

    pos = coord2pos(x, y)
    if radius == VISION_RADIUS:
        reset_dfs_buffer()

    if dfs_buffer[pos]:
        # already traversed
        return
    
    # mark current spot as visible and traversed
    fog[pos] = False
    dfs_buffer[pos] = True
    if radius == 0:
        return

    # check surroundings
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            if abs(dx) + abs(dy) != 1:
                continue

            check_vision(x + dx, y + dy, radius-1)

# initial fog
check_vision(*pos2coord(PLAYER_POS), VISION_RADIUS)

# display_level()

# game loop
while True:
    display_level()
    key = input("> ")

    if not key:
        break

    handle_input(key.lower())
