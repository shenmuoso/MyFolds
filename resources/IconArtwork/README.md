# MyFolds screenshot artwork · 2026-11-22

The two user-supplied screenshots are preserved in `source/`. The white folder
is the light appearance; the black folder is the dark appearance.

`scripts/prepare-icon-artwork.py` removes only the exterior RGB(235,235,235)
screenshot matte, fills enclosed regions to protect the frosted material,
unmattes the antialiased exterior boundary, and aligns both silhouettes on
1024 × 1024 transparent canvases. Both visible bounds are 832 × 632 pixels at
(96,196). Regeneration needs Pillow and NumPy; ordinary builds do not.

The processed masters are copied into `resources/MyFoldsFolder.icon/Assets/`.
This is the current production Icon Composer document. It selects the supplied
light/dark images with `image-name-specializations` and adds the native system
icon container. Effects are disabled on the artwork layer: the source's frost,
paper, and lighting are raster artwork, not separately reconstructed dynamic
glass layers. macOS applies its container and icon-style treatment.

`scripts/build-icons.sh` compiles this document to `Assets.car` and
`MyFoldsFolder.icns`, and exports the exact same light/dark renders for settings,
onboarding, About, and the running Dock icon. `MyFoldsIcon.icon` is the previous
design and is no longer a build input.
