module sharex.config.config;

public import sharex.config.general;

interface IConfig
{
	void load();
	void save();
}

static IConfig[string] configProviders;

static void load()
{
	foreach (name, config; configProviders)
		config.load();
}

static void save()
{
	foreach (name, config; configProviders)
		config.save();
}
