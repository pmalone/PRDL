package eu.endorse.test;

import eu.endorse.prdl.*;

import java.io.*;

import org.antlr.runtime.*;
import org.antlr.stringtemplate.*;
import org.antlr.stringtemplate.language.*;

public class PRDLToDroolsTranslator {
    public static StringTemplateGroup templates;
    
    public static final int POLICY_FILE = 0;
    public static final int POLICY_FILE_CONTENTS = 1;
    public static final int POLICY_STATEMENT = 2;
    public static final int PERMISSION_RULE = 3;
    public static final int PROHIBITION_RULE = 4;
    public static final int OBLIGATION_RULE = 5;

    public static void main(String[] args) throws Exception {
    	String inputFileName;
		String templateFileName;
		
		//System.out.println("UserDir is: " + System.getProperty("user.dir"));
		
		if (args.length == 1) {
			inputFileName = args[0];
			templateFileName = "/Drools.stg";
		} else if(args.length >= 2) {
			inputFileName = args[0];
			templateFileName = args[1];
		}
		else {
			//inputFileName = System.getProperty("user.dir") + "/PRDLPoliciesTest";
			inputFileName = "/PRDLPoliciesTest";
			//System.out.println("Input file is: " + inputFileName);
			templateFileName = "/Drools.stg";
		}
		templates = new StringTemplateGroup(getFileInputStreamReader(templateFileName),
						    AngleBracketTemplateLexer.class);
	
		/* Take input from String. */
		//int type = PERMISSION_RULE;
		//String inputString = "CustomerSupport MAY VIEW ON customerRecords,healthRecords FOR goodReason,arbitraryReason";
		//CharStream input = new ANTLRStringStream(inputString);
		
		/* Take input from File. */
		int type = POLICY_FILE_CONTENTS;
		CharStream input = new ANTLRStringStream(getFileInputStreamReaderAsString(inputFileName));
		
		String parsedOutput = prdlParse(type, input);
		
		System.out.println(parsedOutput);
	
    }
    
    public static String prdlParse(int ruleType, CharStream input) {
    	PRDLLexer lexer = new PRDLLexer(input);
		CommonTokenStream tokens = new CommonTokenStream(lexer);
		PRDLParser parser = new PRDLParser(tokens);
		parser.setTemplateLib(templates);
		RuleReturnScope r = null;
		
		String result = "Did not parse.";
		try {
			switch(ruleType) {
				case POLICY_FILE : r = parser.policy_file(); break;
				case POLICY_FILE_CONTENTS : r = parser.policy_file_contents(); break;
				case PERMISSION_RULE : r = parser.permission(); break;
				case PROHIBITION_RULE : r = parser.prohibition(); break;
				case OBLIGATION_RULE : r = parser.obligation(); break;
				
				default : // Do nothing.
			}
			
			if(r!=null) {
				Object template = r.getTemplate();
				if(template != null) {
					result = template.toString();
				} else {
					result = "Null template.";
				}
			} else {
				result = "Invalid ruleType specified.";
			}
		} catch (RecognitionException e) {
			e.printStackTrace();
		}
		
		return result;
    }
    
    private static String getFileInputStreamReaderAsString(String fileName) {
    	BufferedReader reader = new BufferedReader(getFileInputStreamReader(fileName));
    	
    	StringBuilder sb = new StringBuilder();
    	int ch = 0;
    	try {
			while((ch = reader.read()) != -1) {
				sb.append((char) ch);
			}
			reader.close();
		} catch (IOException e) {
			e.printStackTrace();
		}
    	
    	return sb.toString();
    }
    
    private static InputStreamReader getFileInputStreamReader(String fileName) {
    	InputStream is = new PRDLToDroolsTranslator().getClass().getResourceAsStream(fileName);
    	
    	return new InputStreamReader(is);
    }
}
