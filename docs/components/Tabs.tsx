'use client'

import { Children, useId, useRef, useState, type ReactNode } from 'react'

export function Tabs({ labels, children }: { labels: string[]; children: ReactNode }) {
  const panels = Children.toArray(children).filter(child => typeof child !== 'string')
  const [selected, setSelected] = useState(0)
  const id = useId()
  const buttons = useRef<(HTMLButtonElement | null)[]>([])
  if (panels.length !== labels.length) throw new Error('Tabs need one panel per label')
  return (
    <div className="tabs">
      <div role="tablist" aria-label="Instructions">
        {labels.map((label, i) => <button key={label} ref={el => { buttons.current[i] = el }}
          type="button" role="tab" id={`${id}-tab-${i}`} aria-controls={`${id}-panel-${i}`}
          aria-selected={selected === i} tabIndex={selected === i ? 0 : -1}
          onClick={() => setSelected(i)} onKeyDown={event => {
            const target = event.key === 'ArrowRight' ? (i + 1) % labels.length
              : event.key === 'ArrowLeft' ? (i + labels.length - 1) % labels.length
              : event.key === 'Home' ? 0 : event.key === 'End' ? labels.length - 1 : null
            if (target !== null) { event.preventDefault(); setSelected(target); buttons.current[target]?.focus() }
          }}>{label}</button>)}
      </div>
      {panels.map((panel, i) => <div key={i} role="tabpanel" tabIndex={0}
        id={`${id}-panel-${i}`} aria-labelledby={`${id}-tab-${i}`} hidden={selected !== i}>{panel}</div>)}
    </div>
  )
}
