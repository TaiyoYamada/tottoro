# App icon

The app icon is the countdown ring from the app around a lock, on blue. The development build (Tottoro Dev) uses orange, so the two are easy to tell apart on the same device.

The icons that the app uses are Icon Composer files:

- `Tottoro/Resources/AppIcon.icon`: the App Store build (Release)
- `Tottoro/Resources/AppIcon-Dev.icon`: the development build (Debug)

`Configs/Debug.xcconfig` and `Configs/Release.xcconfig` choose between them with `APP_ICON_NAME`.

To change the icon, open the `.icon` file in Icon Composer (in Xcode, Open Developer Tool > Icon Composer). Icon Composer adds the glass, the shadow and the dark and tinted appearances. Change both files the same way, except for the background color.

## The drafts in this folder

The layers in the `.icon` files were made from these SVGs. They are kept so that the shapes can be changed and exported again.

| File | What it is |
|---|---|
| `ring.svg` | The countdown ring |
| `lock.svg` | The lock, in front of the ring |
| `background.svg`, `background-dev.svg` | The background colors. The `.icon` files do not use them directly; they use Icon Composer's automatic gradient from a similar color |
| `preview.svg` | All layers together, only for looking at them |
