package com.dlizarra.starter;

public class StarterMain {

	public static void main(final String... args) {
		new StarterApplication(AppConfig.class).run(args);
        Parser parser = new Parser("simple.kmv");
        System.out.println(parser.getJson());
	}

}
