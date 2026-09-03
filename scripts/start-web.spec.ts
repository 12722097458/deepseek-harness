import { existsSync } from 'node:fs'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { describe, expect, it } from 'vitest'

const launcher = fileURLToPath(new URL('../deploy/start-web.ps1', import.meta.url))
const batchLauncher = fileURLToPath(new URL('../deploy/start-web.bat', import.meta.url))
const shellLauncher = fileURLToPath(new URL('../deploy/start-web.sh', import.meta.url))

describe('Web launchers', () => {
  it('ships platform wrappers alongside the PowerShell launcher', () => {
    expect(existsSync(launcher)).toBe(true)
    expect(existsSync(batchLauncher)).toBe(true)
    expect(existsSync(shellLauncher)).toBe(true)
  })
})

describe.skipIf(process.platform !== 'win32')('Windows Web launcher', () => {
  it('rejects an invalid port before attempting a build or launch', () => {
    const result = spawnSync('pwsh', [
      '-NoProfile',
      '-File',
      launcher,
      '-Port',
      '0',
    ], { encoding: 'utf8' })

    expect(result.status).not.toBe(0)
    expect(`${result.stdout}\n${result.stderr}`).toContain('Port')
  })
})
