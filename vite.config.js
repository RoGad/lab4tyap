import { defineConfig } from 'vite';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

export default defineConfig({
    plugins: [
        {
            name: 'opal-ruby',
            async transform(code, id) {
                if (id.endsWith('.rb')) {
                    try {
                        const { stdout } = await execAsync(`opal -c ${id}`, {
                            maxBuffer: 10 * 1024 * 1024
                        });
                        return {
                            code: stdout,
                            map: null
                        };
                    } catch (error) {
                        console.error('Opal compilation error:', error);
                        throw error;
                    }
                }
            }
        }
    ]
});