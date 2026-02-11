# xDPC

> **Notice from @FezzedOne: This is a hard fork of @CptSalt's Dynamic Proximity Chat.** I've decided to make a hard fork of the @CptSalt's mod for reasons I will not go into here; DM me on Stoat or Discord (**@fezzedone**) for more info. The readme has been revised to fix formatting issues and include commands added largely via my PRs. xDPC is _not_ fully network-compatible with Captain Salt's Dynamic Proximity Chat; in particular, nickname/alias recognition priorities are ranked oppositely between the mods.

## About

> This is the original _About_ section from the readme for @CptSalt's Dynamic Proximity Chat at the time of the hard fork, with a few minor spelling corrections.

This is a chat mod that takes very heavy inspiration from a very technically impressive server that closed some time ago; this is my attempt to recreate some of those functions from memory. It is built based on Degranon's Star Custom Chat proximity plugin, and thus requires the base mod, as well as StarExtensions or OpenStarbound.

In essence, this mod searches for certain characters to dictate different modes within the message, then it determines whether or not the receiving player can see the components of the message. Quotes can be garbled or muffled, and there are modifiers for things like volume.

The mod additionally adds virtually infinite languages for roleplaying. You can create a language with a code to use in chat, which encodes any dialogue until the language is set again in the message.
Each character has a proficiency for any given language. This proficiency depends on how many language items the character has in their inventory, between 0 and 10.
Users who only know some (or none) of a language will have some of the words scrambled depending on the proficiency.

There is also an included configurable autocorrect feature. With this feature, you can add mistyped words and their intended word to a list.
When activated, the feature will scan messages you send and replace any words you've provided in the list.
You can add and remove words to a list, and can choose to turn the feature on or off (it is off by default).

Note that this mod will require everyone who interacts with you to have it, as they will not be able to see your messages without the mod.

## Requirements

This mod requires [StarCustomChat](https://github.com/KrashV/StarCustomChat) 1.8.8+ by Degranon, and one of the following:

- [xStarbound](https://github.com/xStarbound/xStarbound) v3.5.2.1+. Recommended.
- [OpenStarbound](https://github.com/OpenStarbound/OpenStarbound) 0.1.8+.
- [StarExtensions](https://github.com/StarExtensions/StarExtensions) v.1.9.24+.

Additionally, xDPC is compatible with [StarCustomChatRP](https://github.com/KrashV/StarCustomChatRP) (SCCRP).

## Usage

### Chat controls

- Actions - `He does this.`: Default state, writing a full message without any quotes or indicators will post an action. Actions require line of sight to be received.
- Quotes - `"Hello."`: Use `""` to open and close quotes. They have a shorter range than actions, but do not need direct line of sight so long as there is open air between the sender and receiver.
- Sounds - `<bang>`: Use `<>` to open and close sounds. They are identical to quotes in function, but are intended for noises made by things, rather than people. If used within a quote, the text inside is not language-scrambled; use this for names.
- Volume Control - `:+`/`:-`/`:=` : Use `:+` (with up to four `+`s) to increase the volume of a quote/sound. Use `:-` (with up to four `-`s) to decrease it. Use `:=` to reset it. You can make noises louder/quieter four times in each direction (`:++++`, `:----`)
- Global OOC - `(((Hello.)))`: Use `(())` for global OOC. Global OOC is seen by all players on the server, regardless of whether they have xDPC enabled.
- Local OOC - `((Hello.))`: Use `(())` for local OOC. Local OOC is seen by all players on the same world (or "bridged" worlds, depending on server configuration) if `/proxooc` _and_ `/sendlocal` are both enabled; otherwise its range is limited to 200 tiles.
- Proximity OOC - `<<Hello>>`: Use `<<>>` for proximity OOC. Proximity OOC has a 200-tile range regardless of `/proxooc` and `/sendlocal` settings.
- Radio - `{"Hello." Does something on the radio.}`: Use `{}` for local radio chat. This can be seen through walls, but is distinct from OOC, and supports languages inside quotes. Anything outside quotes but within braces is considered a "radio action" and is not language-scrambled.
- Global radio - `{{"Hello!"}}`: Use `{{}}` for global radio chat. This can be seen by all players on the server, and supports languages inside Quotes. Anything outside quotes but within braces is considered a "radio action" and is not language-scrambled.
- Emphasis - `Look *there*`: Use `**` for emphasis. This changes nothing about the chat, but makes it anything inside of it a specific color.
- Item Emphasis - `She shows the \Titled Object\ to him.`: Functionally identical to normal emphasis, but uses a different color.
- Rolling - `|100|`: Rolls a number between 1 and the provided maximum. The value should be consistent between players. Also supports basic dice notation, including the operators `+`, `-`, `*` and `/`, and the GURPS-style `d` for `d6`; e.g., `|3d6+2|` or `|3d+2|` rolls 3 six-sided dice and adds 2 to the result, while `|d20|` rolls a twenty-sided die.

## Languages, commcodes and comms aliases

Languages in this mod work by checking player inventories for items that are created with language codes made up of some amount of letters. Depending on how many items with a given code a player has, they will understand more or less of a language.

Someone who's 90/80/50/etc% proficient will know about 90/80/50/etc% of the words in the language. This proficiency can be increased or decreased with more or fewer items in your inventory. By default, the language `[!!]` is universal, and everyone can understand it regardless of whether or not they have any items with the code.

Known words are unique to each player and language, and each language's scrambling seed is unique.

- For (arbitrary) example: The language `[LA]` will always encode "Hello" to something like "Mylli", and the language `[PT]` will always encode "Hello" to something like "Jotta".

Languages also have their own color for scrambled words, they also stay the same for a given language.

Using empty brackets (`[]`) will reset the active language to the character's default language, or (`[!!]`) if the character does not have one.

You can have multiple default languages, the mod will find the first one in your inventory. Just remember to switch them around when you need them.

- _Note:_ Language items show up in the crafting components section of your inventory, since they're components to craft dialogue, or something like that.

Commcodes in this mod are also specified in brackets (e.g., `[10]` or `[172.2]`); disambiguation is done by checking whether the brackets surround a number (can be an integer or a number with decimal dust, used as a commcode) or anything else (assumed to be a language code).

Comm aliases are also specified in brackets (e.g., `[Alias]`) and (on xStarbound) may contain spaces. If a comm alias and a language code share the same name, the comm alias takes precedence, so make sure to avoid using language codes as comm aliases.

## Recognition system

This mod has a character name recognition system for xDPC messages. For the most part, the system is transparent and will mark a character's name as recognised to other players within earshot who can see the character's name unscrambled. Unrecognised characters have their names show up as `???` to characters who don't recognise them.

Character nicknames (called aliases) are also supported. The highest-priority recognised alias or name will be the one that shows up as the character's name in xDPC chat messages (note that this is inverted on standard Dynamic Proximity Chat!). Priority can be any integer from -10 to 10. The character's primary name is priority 0 and there cannot be an alias of that priority.

To add an alias or nickname of a given priority, use `/addalias <name> <priority>`. On xStarbound, the name may contain spaces if surrounded by quotes; otherwise, only single-word nicknames and aliases are allowed. This can be used for codenames, etc., that other characters may know yours by. If you use `/addalias` with a priority value that already has an alias assigned to it, the alias at that priority value is replaced with the new one.

To bypass the recognition system for a given character, use `/skiprecog`, allowing everyone to see the character's name

To change the name shown to characters who don't recognise your character at all, use `/addalias <name> ?` on that character. Technically, this is an alias of priority `?`, which means that any other recognised alias or name the character has will override it.

Use `/resetrecog` to reset your character's "memory" of other characters' names and aliases. Useful for amnesiacs!

Use `/resetalias` to reset your character's own aliases. Note that this does _not_ automatically reset other characters' existing "memories" of your recognised names and aliases.

Use `/grouprecog <group name>` to set your character's "recognition group", i.e., the set of characters who automatically know your character's "real" name; all characters in the same group automatically recognise each other in xDPC chat. This can be used for IC factions. New characters start out with no recognition group by default. Use `/grouprecog none` or `/grouprecog reset` by itself to remove your character's recognition group.

Use `/apply <priority>` to "grant" recognition up to a certain priority level (remember that 0 is the priority level of your character's primary name) to a given character running xDPC, selected by invoking `/chid` with your mouse cursor on the character you want to grant recognition to; this can't be used to _lower_ another character's recognition level or remove recognition, but _can_ be used to update any alias at the same level.

### Typo Correction

You can add and remove typos from a list that's stored in your player file.

Once you've added and removed the typos to your liking, you should then use the /toggletypos, /showtypos or /checktypo commands to make sure the tool is active or inactive. When you add a typo and correction, the mod will scan and replace any typos that match that word before sending your message if the typo correction tool is active.

- _Note:_ Typos will only be corrected as words with punctuation or spaces around them, excluding language brackets.

### Commands

> _Note:_ On xStarbound, all string arguments, except those used by `/addtypo` and `/removetypo`, can include spaces if surrounded by quotes.

`/newlangitem [name (string)] [code (string)] [count (number)] [default (true/false)] [color (text colour code name or hex code)]` - Creates new language items for your character. Spaces are accepted within the language name and code if you surround these arguments with quotes.

- `name`: The name of the language.
- `code`: The code that the language uses.
- `count`: The number of items you're going to spawn, between 1 and 10. This determines your character's proficiency with the language.
- `default`: Whether or not the language is a default language, meaning it will automatically be used when no code is provided.
- `color`: A custom color in which you'll see scrambled words of the language, otherwise they'll be random. Can be a colour name like `green` or a hex code like `#bb2222`.
  - _Note:_ Since this mod is client-side, only you will see the color you set for the language. If you make an item with `blue`, and someone else makes the same item with `red`, you'll see it as blue and they'll see it as red.

`/addtypo typo (string), correction (string)` - Adds a typo to your typo list

- `typo`: The mistyped word, such as "hte, adn, weast, s"
- `correction`: The intended word, such as "the, and, east, a"

`/removetypo typo (string)` - Removes a typo from your typo list

- `typo``: The typo to remove

> _Note:_ Correction is not provided here, since you typically wouldn't need to remove a word based on what it corrects to.

`/toggletypos` - Activates or deactivates typo correction; off by default.

`/checktypo` - Checks the status of the typo correction tool.

`/showtypos` - Shows the list of saved typos you have, and if the tool is on or off.

`/proxlocal` - Toggles whether or not messages sent in "Local" are processed as dynamic messages.

`/sendlocal` - Toggles whether or not dynamic messages are sent via local chat. These will still be processed as dynamic messages.

> _Tip:_ Turn on `/sendlocal` for local OOC and radio messages to be heard across the world.

`/proxooc` - Toggles whether or not local OOC chat (`((...))`) sent as xDPC chat is range-capped like proximity OOC (`<< ... >>`).

`/commcodes`: Lists all comm codes your character is listening in on. Comm codes are saved on a per-character basis. (And handled appropriately on xStarbound if you have multiple characters loaded!)

`/commcode [$newDefault]`: Shows you your default commcode for sending messages without a comm code specifier, or if specified, sets your default. Setting your default to `-` means you must always explicitly specify a commcode in order for roleplay in comms brackets to show up as comms. You may specify your default commcode by its alias.

`/addcommcode $newCommCode [$alias]`: Adds or modifies a listened comm code, optionally adding, modifying or (if left unspecified) removing an alphanumeric alias. Aliases are handled before language code checks — i.e., if [ABC] is an alias, it won't be parsed as a language code when you send messages.

`/removecommcode $commCodeOrAlias`: Removes a listened comm code. You may specify the code to remove by its alias.

`/chatbubble`: Toggle chat bubbles for the character; this applies to _all_ messages! Even if chat bubbles are enabled, xDPC messages will show up as `...` in the bubble.

`/addalias`, `/skiprecog`, `/grouprecog`, `/resetalias`, `/resetrecog`, `/apply`: See _Recognition system_ for more.

`/setname <name>`: Sets your character's primary name, as shown in the character list and in server connection messages (if the server is configured to display them). Requires xStarbound.

> **Note:** If you want to change your character's name on xStarbound with xDPC installed, use `/setname` instead of `/identity set name`. This is because xDPC "controls" the character's name and will revert changes made to the name stored in the character's identity upon any disconnection or warp while installed. It's safe to make "offline" changes to the name in the player's `"identity"` while the game is not running; xDPC respects these changes.

`/nametag <name tag>`: Sets your character's name tag, as shown above the character in game when **Alt** is held. Use `/nametag` with no argument to clear the name tag. Requires xStarbound and OpenStarbound; quotes for names with spaces are supported on both clients. If using xStarbound, hidden or modified name tags are hidden or modified for all clients; if using OpenStarbound, hidden or modified name tags are modified only for OpenStarbound clients.

> **Note:** On new characters or on characters that haven't been used with xDPC before, name tags are hidden by default unless otherwise configured for the character. If using xStarbound, uninstalling xDPC reverts all name tag changes; if changes aren't fully reverted (due to a sudden disconnection, etc., with the mod installed), reinstall xDPC and load any characters with empty names or wrong names shown on the character selection screen at least once, then uninstall again.

## Tips

- `[!!]` can be used for the code in a language item, so it may be worthwhile to generate a set of default language items with that code in case you make others later for niche situations
- Since languages are managed with items, you can share them between players and quickly add/delete them.
- Sounds and quotes have a different volume manager, you can run a string like `":++HEY" <:--scuffle> "COME HERE!!"`, and the sound will have "-2" volume, while the quotes will have "+2" for both segments.
