const fs = require('node:fs');
const path = require('node:path');
const { Client, Collection, Events, GatewayIntentBits, MessageFlags, EmbedBuilder } = require('discord.js'); // Changed MessageEmbed to EmbedBuilder
const { token, welcomeChannelId } = require('./config.json');

const client = new Client({ intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages, GatewayIntentBits.GuildMembers] }); // Added GuildMessages intent

client.commands = new Collection();
const foldersPath = path.join(__dirname, 'commands');
const commandFolders = fs.readdirSync(foldersPath);

for (const folder of commandFolders) {
	const commandsPath = path.join(foldersPath, folder);
	const commandFiles = fs.readdirSync(commandsPath).filter(file => file.endsWith('.js'));
	for (const file of commandFiles) {
		const filePath = path.join(commandsPath, file);
		const command = require(filePath);
		if ('data' in command && 'execute' in command) {
			client.commands.set(command.data.name, command);
		} else {
			console.log(`[WARNING] The command at ${filePath} is missing a required "data" or "execute" property.`);
		}
	}
}

client.once(Events.ClientReady, readyClient => {
	console.log(`Ready! Logged in as ${readyClient.user.tag}`);
});

client.on(Events.InteractionCreate, async interaction => {
	if (!interaction.isChatInputCommand()) return;
	const command = interaction.client.commands.get(interaction.commandName);

	if (!command) {
		console.error(`No command matching ${interaction.commandName} was found.`);
		return;
	}

	try {
		await command.execute(interaction);
	} catch (error) {
		console.error(error);
		if (interaction.replied || interaction.deferred) {
			await interaction.followUp({ content: 'There was an error while executing this command!', flags: MessageFlags.Ephemeral });
		} else {
			await interaction.reply({ content: 'There was an error while executing this command!', flags: MessageFlags.Ephemeral });
		}
	}
});

client.on('guildMemberAdd', async member => {
	// Fetch the channel using the ID
	//const channel = member.guild.channels.cache.get(welcomeChannelId);
	const channel = client.channels.cache.get(welcomeChannelId); // Replace 'CHANNEL_ID' with the ID of the channel you want to send the message to

	if (!channel) return; // Check if the channel exists and is a text channel

	const embed = new EmbedBuilder() // Changed to EmbedBuilder
		.setTitle(`Welcome to ${member.guild.name}`)
		.setDescription(
			'Welcome to TheLevelingGuild, your one stop shop for leveling and raiding on Living-Flame-EU!' +
			'\n'+
			`\nWe are happy to have you ${member.user}!`+
			'\n'+
			'\nPlease change your name on Discord to your main character in the guild.' +
			'\n'+
			'\nCheck out our rules at https://discord.com/channels/934791725266894889/940587555055870022.' +
			'\n'+
			'\nCheck out our crafting requests at https://discord.com/channels/934791725266894889/1333715937354059888.' +
			'\n'+
			'\nAny Improvements? Please post them at https://discord.com/channels/934791725266894889/1331499774041522300.' +
			'\n'+
			'\Want to raid? Use the raid signup channels.' +
			'\n'+
			'\nPlease welcome our newest member!'
		)
		.setColor('#2F3136')
		.setThumbnail(member.displayAvatarURL({ dynamic: true }))
		.setTimestamp()
		.setFooter({ text: 'Thanks for joining!' }); // Updated footer syntax

	try {
		console.log("sending welcome message")
		await channel.send({ embeds: [embed] });
	} catch (error) {
		console.error(`Could not send welcome message: ${error}`);
	}
});

client.login(token);
