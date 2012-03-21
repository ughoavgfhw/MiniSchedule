# MiniSchedule

MiniSchedule is a simple, menu bar app. It allows quick access to the events in your iCal calendars.

## Features

- Choose which calendars to show events from
- Specify a time frame for which events to show
    - Today, tomorrow, the next 12/24 hours, or a custom range
- Events show time, event title, and location
- View events in the menu or via a popup window
- Customize the hot key using System Preferences
    - Use the keyboard preferences to create a shortcut with the name "Open Schedule Window"

## Planned

- Use tooltips to show extended information
- Click an event to open it in iCal

## What you can do

- Add character map files. These are necessary to use the hot key, and only the standard US layout is currently supported. See `Charmap Format.md` for a description of the format. All you need is a hex editor and a knowledge of the keycodes for some layout.
    - I might make a tool to simplify creation of these at some point. Feel free to create one yourself if you can't wait.
    - I have an idea for finding this information at runtime, which would make these files unnecessary, but I'm not sure if it will work well or when it will be ready.
- Bug reports and feature requests are always welcome. Even better, fix bugs or implement a feature and send a pull request.