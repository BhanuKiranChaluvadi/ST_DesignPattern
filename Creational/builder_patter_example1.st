///The class Product is just a plain bluprint of the components of the object to be built.
///The final Product may ot may not contain the all the Parts listed on the Product declaration
/// rather only the parts in the specifications sent by the client.
{attribute 'enable_dynamic_creation' := ''}
FUNCTION_BLOCK Product
VAR_INPUT
	///List of possible parts to be build in a final Product object
	mainPart: STRING;
	part1: STRING;
	part2: STRING;
	part3: STRING;
END_VAR
    ///Method to be used in the visualization element for an easier String handling
    METHOD toString : STRING
    VAR
        ///Local variable to join together and store the pieces of String
        tempString: STRING;
    END_VAR
        //tempString joins together "Main Part" and "Part 1" of the Product object
        tempString := CONCAT(THIS^.mainPart , THIS^.part1);
        //tempString joins together its current value and "Part 2" of the Product object
        tempString := CONCAT(tempString , THIS^.part2);
        //tempString joins together its current value and "Part 3" of the Product object
        tempString := CONCAT(tempString , THIS^.part3);
        //The final result is sent as the output of this method
        toString := tempString;
    END_METHOD
END_FUNCTION_BLOCK

///Builder interface to declare all needed parts to be built
INTERFACE ITF_Builder
    ///Illustrative method of the pattern to set the main part
    METHOD Set_Main_Part
    VAR_INPUT
        ///Illustrative value (object because it is a TRING) to be set as a product part
        mainPart: STRING;
    END_VAR
    
    ///Illustrative method of the pattern to set the part1
    METHOD Set_Part1
    VAR_INPUT
        ///Illustrative value (object because it is a TRING) to be set as a product part
        part1: STRING;
    END_VAR

    ///Illustrative method of the pattern to set the part2
    METHOD Set_Part2
    VAR_INPUT
        ///Illustrative value (object because it is a TRING) to be set as a product part
        part2: STRING;
    END_VAR

    ///Illustrative method of the pattern to set the part3
    METHOD Set_Part3
    VAR_INPUT
        ///Illustrative value (object because it is a TRING) to be set as a product part
        part3: STRING;
    END_VAR
END_INTERFACE


///This is the concrete builder class, reponsible for building the final product object
FUNCTION_BLOCK ConcreteBuilder IMPLEMENTS ITF_Builder
VAR
	///Holds an internal reference to how the final product shoud be so the builder class can build it on the fly /// Contiene una referencia interna sobre cómo debe ser el producto final para que la clase constructora pueda construirlo sobre la marcha.
	/// without any help from other classes exepting the Director class that is going to be passing the special /// sin ninguna ayuda de otras clases excepto la clase Director que va a pasar el especial
	///specifications to the builder.///especificaciones para el constructor.
	localProduct: Product;
	///Stores the specifications, sent by the client, of the final product to be built.
	///Almacena las especificaciones, enviadas por el cliente, del producto final a construir.
	specifications: ARRAY[1..4] OF STRING;
END_VAR

METHOD fb_init
VAR_INPUT
	/// TRUE: the Retain-variables are initialized (reset warm / reset cold)
	bInitRetains: BOOL;
	/// TRUE  the instance will be copied to the copy-code afterward (online change)	
	bInCopyCode: BOOL;
	///The constructor receives the specifications for this ConcreteBuilder instance 
	///Just in case the concrete builder could change the specifications in the future, otherwise
	/// this specifications should be constant.
	specs: ARRAY[1..4] OF STRING;
END_VAR

    //Stores the specifications on its own specifications field.
    THIS^.specifications := specs;

END_METHOD

///Illustrative method of the pattern to get the main part
METHOD Get_Main_Part : STRING
    //Returns the object stored in the built product THIS^.localProduct.mainPart
    Get_Main_Part := THIS^.localProduct.mainPart;
END_METHOD

///Illustrative method of the pattern
METHOD Get_Result : Product
    //The concrete builder, after it builts the final object of class product, returns the 
    // final product object 
    Get_Result := THIS^.localProduct;
END_METHOD

///Illustrative method of the pattern to set the part1
METHOD Set_Part1
VAR_INPUT
	///Illustrative value (object because it is a TRING) to be set as a product part
	part1: STRING;
END_VAR
    //Sets the passed value to its corresponding field. 
    //We can say that the the final product is in process of being built.
    //So this is a step into building the final product done by the builder.
    THIS^.localProduct.part1 := part1;
END_METHOD

END_FUNCTION_BLOCK

///The director class is responsible to delegate the construction of the final product object 
/// to a concrete builder object.
{attribute 'enable_dynamic_creation' := ''}
FUNCTION_BLOCK Director
VAR_INPUT
	///Reference to the builder that is going to be building the final product object.
	///Referencia al constructor que construirá el objeto del producto final.
	{attribute 'old_input_assignments' := ''}
	inputConcreteBuilder: ConcreteBuilder(specs := inputConcreteBuilder.specifications);
END_VAR
VAR
	///Holds a reference to the concrete builder object to send the specifications of the final product to it.
	/// Contiene una referencia al objeto constructor concreto para enviarle las especificaciones del producto final
	{attribute 'old_input_assignments' := ''}
	concreteBuilder: ConcreteBuilder(specs := THIS^.concreteBuilder.specifications);
END_VAR
    //Stores the reference to which builder will be building the final product object in its own field THIS^.concreteBuilder
    //Almacena la referencia a qué constructor construirá el objeto del producto final en su propio campo THIS^.concreteBuilder
    THIS^.concreteBuilder := inputConcreteBuilder;

///This constructor is called at instanciation it is necessary to instanciate the Director instance.
///The specifications of the concreteBuilder instance stored in the Director instance should be set first by the client
/// otherwise a Data Recursion error is caused
METHOD fb_init
VAR_INPUT
	/// TRUE: the Retain-variables are initialized (reset warm / reset cold)
	bInitRetains: BOOL;
	/// TRUE  the instance will be copied to the copy-code afterward (online change)
	bInCopyCode: BOOL;
	///Reference a concreteBuilder instance to instanciate the Director.
	{attribute 'old_input_assignments' := ''}
	inputConcreteBuilder: ConcreteBuilder(specs := defaultArray);
END_VAR
VAR
	///Variable to isntanciate the concreteBuilder instance on the input section. It does not affect the Directors instanciation.
	defaultArray: ARRAY[1..4] OF STRING := ['Default', 'Default', 'Default', 'Default'];
END_VAR
    //Creates the concreteBuilder instance that will be building the final product object in its own field THIS^.concreteBuilder
    //This instance is empty because we can not use Data Recursion with the inputConcreteInstance instanciation.
    //So this concreteBuilder instance should be changed by the client before a Construct() request is called on the Director for the first time only.
    THIS^.concreteBuilder := inputConcreteBuilder;
END_METHOD

///This method is going to be called by the client when a new Product object must be built
METHOD Construct : Product
    //The Director tells its concreteBuilder instance to build the final product step by step passing the specifications stored in the 
    // concreteBuilder array THIS^.specifications[1..4]

    //Step 1 "Main Part"
    THIS^.concreteBuilder.Set_Main_Part(THIS^.concreteBuilder.specifications[1]);
    //Step 2 "Part 1"
    THIS^.concreteBuilder.Set_Part1(THIS^.concreteBuilder.specifications[2]);
    //Step 3 "Part 2"
    THIS^.concreteBuilder.Set_Part2(THIS^.concreteBuilder.specifications[3]);
    //Step 4 "Part 3"
    THIS^.concreteBuilder.Set_Part3(THIS^.concreteBuilder.specifications[4]);

    //Finally the concreteBuilder instance in the Director object delivers the final result as a Product object
    //Finalmente, la instancia de concreteBuilder en el objeto Director entrega el resultado final como un objeto Producto
    Construct := THIS^.concreteBuilder.Get_Result();
END_METHOD
END_FUNCTION_BLOCK

