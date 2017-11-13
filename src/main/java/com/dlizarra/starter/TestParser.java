package com.dlizarra.starter;

import org.junit.Assert;
import org.junit.Test;

public class TestParser {
    @Test
    public void testInit() {
      //Parser parser = new Parser("../../../../../../models/simple2.kmv");
      Parser parser = new Parser("../../../models/simple2.kmv");
      Assert.assertNotNull(parser);
      Assert.assertNotNull(parser.getJson());
    }
}
