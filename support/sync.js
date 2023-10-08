const { execSync } = require('child_process');

const blueprintPath = process.argv[2]

if (!blueprintPath) {
    console.error("No blueprint path provided. Usage: yarn sync <blueprint-path>");
    process.exit(1);
}

try {
    const command = `yarn add-skills-from-blueprint ${blueprintPath} && yarn --force && yarn build.skills`;
    execSync(command, { stdio: 'inherit' });
} catch (error) {
    console.error('Error running sync', error);
}
