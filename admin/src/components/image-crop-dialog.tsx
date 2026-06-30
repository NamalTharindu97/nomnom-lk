"use client"

import { useState, useCallback } from "react"
import Cropper, { type Area } from "react-easy-crop"
import "react-easy-crop/react-easy-crop.css"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"

interface ImageCropDialogProps {
  open: boolean
  imageUrl: string
  fileName: string
  index: number
  total: number
  onCropComplete: (blob: Blob) => void
  onCancel: () => void
}

function createImage(url: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const image = new Image()
    image.crossOrigin = "anonymous"
    image.onload = () => resolve(image)
    image.onerror = () => reject(new Error("Failed to load image"))
    image.src = url
  })
}

async function getCroppedBlob(imageSrc: string, croppedAreaPixels: Area): Promise<Blob> {
  const image = await createImage(imageSrc)
  const canvas = document.createElement("canvas")
  canvas.width = croppedAreaPixels.width
  canvas.height = croppedAreaPixels.height
  const ctx = canvas.getContext("2d")!
  ctx.drawImage(
    image,
    croppedAreaPixels.x,
    croppedAreaPixels.y,
    croppedAreaPixels.width,
    croppedAreaPixels.height,
    0,
    0,
    croppedAreaPixels.width,
    croppedAreaPixels.height,
  )
  return new Promise((resolve, reject) => {
    canvas.toBlob((blob) => {
      if (blob) resolve(blob)
      else reject(new Error("Canvas toBlob failed"))
    }, "image/jpeg", 0.95)
  })
}

export default function ImageCropDialog({
  open,
  imageUrl,
  fileName,
  index,
  total,
  onCropComplete,
  onCancel,
}: ImageCropDialogProps) {
  const [crop, setCrop] = useState({ x: 0, y: 0 })
  const [zoom, setZoom] = useState(1)
  const [croppedAreaPixels, setCroppedAreaPixels] = useState<Area | null>(null)
  const [processing, setProcessing] = useState(false)

  const handleCropChange = useCallback((location: { x: number; y: number }) => {
    setCrop(location)
  }, [])

  const handleZoomChange = useCallback((z: number) => {
    setZoom(z)
  }, [])

  const handleCropComplete = useCallback((_: Area, croppedPixels: Area) => {
    setCroppedAreaPixels(croppedPixels)
  }, [])

  const handleApply = useCallback(async () => {
    if (!croppedAreaPixels) return
    setProcessing(true)
    try {
      const blob = await getCroppedBlob(imageUrl, croppedAreaPixels)
      onCropComplete(blob)
    } catch (e) {
      console.error("Crop failed:", e)
    }
    setProcessing(false)
  }, [imageUrl, croppedAreaPixels, onCropComplete])

  return (
    <Dialog open={open} onOpenChange={(v) => { if (!v) onCancel() }}>
      <DialogContent
        className="sm:max-w-2xl"
        onEscapeKeyDown={(e) => { e.preventDefault(); onCancel(); }}
        onInteractOutside={(e) => e.preventDefault()}
      >
        <DialogHeader>
          <DialogTitle>
            Crop Image{total > 1 ? ` (${index + 1} of ${total})` : ""}
            <span className="ml-2 text-sm font-normal text-muted-foreground">{fileName}</span>
          </DialogTitle>
        </DialogHeader>
        <div className="relative w-full h-80 bg-muted rounded-md overflow-hidden">
          <Cropper
            image={imageUrl}
            crop={crop}
            zoom={zoom}
            aspect={1 / 1}
            onCropChange={handleCropChange}
            onZoomChange={handleZoomChange}
            onCropComplete={handleCropComplete}
          />
        </div>
        <div className="flex items-center gap-4 px-1">
          <span className="text-xs text-muted-foreground w-12 text-right">Zoom</span>
          <input
            type="range"
            min={1}
            max={3}
            step={0.1}
            value={zoom}
            onChange={(e) => setZoom(Number(e.target.value))}
            className="flex-1 h-2 cursor-pointer accent-primary"
          />
          <span className="text-xs text-muted-foreground w-8 text-right">{zoom.toFixed(1)}x</span>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onCancel} disabled={processing}>
            Cancel
          </Button>
          <Button onClick={handleApply} disabled={processing || !croppedAreaPixels}>
            {processing ? "Cropping…" : "Apply Crop"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
