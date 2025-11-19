require 'native'

class CalculationInputs
  attr_accessor :a, :b, :c, :d, :f, :x

  def initialize(a:, b:, c:, d:, f:, x:)
    @a = a
    @b = b
    @c = c
    @d = d
    @f = f
    @x = x
  end
end

class ArgumentConstraints
  attr_reader :min, :max, :step, :name

  def initialize(min:, max:, step:, name:)
    @min = min
    @max = max
    @step = step
    @name = name
  end
end

class TestCase
  attr_reader :id, :name, :description, :inputs, :expected_result,
              :should_pass, :error_type, :reference_result,
              :max_allowed_error, :expected_behavior

  def initialize(id:, name:, description:, inputs:, expected_result: nil,
                 should_pass: true, error_type: nil, reference_result: nil,
                 max_allowed_error: nil, expected_behavior: nil)
    @id = id
    @name = name
    @description = description
    @inputs = inputs
    @expected_result = expected_result
    @should_pass = should_pass
    @error_type = error_type
    @reference_result = reference_result
    @max_allowed_error = max_allowed_error
    @expected_behavior = expected_behavior
  end
end

class Calculator
  RELATIVE_ERROR_THRESHOLD = 7e-7

  TEST_CASES = [
    TestCase.new(
      id: 1,
      name: "Минимальные значения диапазонов",
      description: "Проверка работы с минимальными допустимыми значениями всех аргументов",
      inputs: CalculationInputs.new(a: 0.01, b: 1, c: 18, d: -0.02, f: 0.0, x: 1.442249),
      expected_result: "Программа должна корректно вычислить результат без ошибок",
      should_pass: true
    ),
    TestCase.new(
      id: 2,
      name: "Максимальные значения диапазонов",
      description: "Проверка работы с максимальными допустимыми значениями всех аргументов",
      inputs: CalculationInputs.new(a: 1.01, b: 312.01741, c: 20, d: 1.4, f: 0.4, x: 1.442249),
      expected_result: "Программа должна корректно вычислить результат без ошибок",
      should_pass: true
    ),
    TestCase.new(
      id: 3,
      name: "Средние значения диапазонов",
      description: "Проверка работы со значениями в середине диапазонов",
      inputs: CalculationInputs.new(a: 0.51, b: 158.0795, c: 19.2, d: 0.7, f: 0.2, x: 1.442249),
      expected_result: "Программа должна корректно вычислить результат без ошибок",
      should_pass: true
    ),
    TestCase.new(
      id: 4,
      name: "Ошибка: неверный шаг для аргумента a",
      description: "Значение a = 0.015 не соответствует шагу 0.01",
      inputs: CalculationInputs.new(a: 0.015, b: 100, c: 19.0, d: 0.5, f: 0.2, x: 1.442249),
      expected_result: "Программа должна показать ошибку: 'Значение не соответствует шагу 0.01'",
      should_pass: false,
      error_type: "invalid_step"
    ),
    TestCase.new(
      id: 5,
      name: "Ошибка: выход за диапазон для аргумента b",
      description: "Значение b = 400 выходит за максимум диапазона [1; 314]",
      inputs: CalculationInputs.new(a: 0.5, b: 400, c: 19.0, d: 0.5, f: 0.2, x: 1.442249),
      expected_result: "Программа должна показать ошибку: 'Значение выходит за допустимый диапазон'",
      should_pass: false,
      error_type: "out_of_range"
    ),
    TestCase.new(
      id: 6,
      name: "Ошибка: деление на ноль",
      description: "Комбинация d и f приводит к знаменателю близкому к нулю",
      inputs: CalculationInputs.new(a: 0.5, b: 101.53088, c: 19.2, d: 0, f: 0, x: 1.442249),
      expected_result: "Программа должна показать ошибку: 'Деление на ноль!'",
      should_pass: false,
      error_type: "division_by_zero"
    ),
    TestCase.new(
      id: 7,
      name: "Ошибка: неверный шаг для аргумента c",
      description: "Значение c = 18.5 не соответствует шагу 0.4",
      inputs: CalculationInputs.new(a: 0.5, b: 101.53088, c: 18.5, d: 0.5, f: 0.2, x: 1.442249),
      expected_result: "Программа должна показать ошибку: 'Значение не соответствует шагу 0.4'",
      should_pass: false,
      error_type: "invalid_step"
    ),
    TestCase.new(
      id: 8,
      name: "Ошибка: отрицательное значение для f",
      description: "Значение f = -0.1 выходит за минимум диапазона [0.0; 0.4]",
      inputs: CalculationInputs.new(a: 0.5, b: 101.53088, c: 19.2, d: 0.5, f: -0.1, x: 1.442249),
      expected_result: "Программа должна показать ошибку: 'Значение выходит за допустимый диапазон'",
      should_pass: false,
      error_type: "out_of_range"
    )
  ]

  CONTROL_CASES = [
    TestCase.new(
      id: 1,
      name: "Контрольный пример №1: Нижняя граница",
      description: "Проверка с минимальными значениями, эталонный результат для верификации",
      inputs: CalculationInputs.new(a: 0.01, b: 1.0, c: 18.0, d: -0.02, f: 0.001, x: 1.442249),
      reference_result: -666.2778,
      max_allowed_error: 7e-7,
      expected_behavior: "Результат должен совпадать с эталонным в пределах допустимой погрешности",
      should_pass: true
    ),
    TestCase.new(
      id: 2,
      name: "Контрольный пример №2: Верхняя граница",
      description: "Проверка с максимальными значениями, эталонный результат для верификации",
      inputs: CalculationInputs.new(a: 1.01, b: 312.01741, c: 20, d: 1.4, f: 0.4, x: 1.442249),
      reference_result: 207.9836,
      max_allowed_error: 7e-7,
      expected_behavior: "Результат должен совпадать с эталонным в пределах допустимой погрешности",
      should_pass: true
    ),
    TestCase.new(
      id: 3,
      name: "Контрольный пример №3: Значения из середины диапазона",
      description: "Проверка с типичными значениями из середины диапазонов",
      inputs: CalculationInputs.new(a: 0.50, b: 158.0796, c: 19.2, d: 0.70, f: 0.200, x: 1.442249),
      reference_result: 186.4215,
      max_allowed_error: 7e-7,
      expected_behavior: "Результат должен совпадать с эталонным в пределах допустимой погрешности",
      should_pass: true
    ),
    TestCase.new(
      id: 4,
      name: "Контрольный пример №4: Граничный случай шага",
      description: "Проверка корректности работы с граничными значениями шага",
      inputs: CalculationInputs.new(a: 0.50, b: 4.14159, c: 18.8, d: 0.00, f: 0.100, x: 1.442249),
      reference_result: 74.3159,
      max_allowed_error: 7e-7,
      expected_behavior: "Результат должен совпадать с эталонным в пределах допустимой погрешности",
      should_pass: true
    ),
    TestCase.new(
      id: 5,
      name: "Контрольный пример №5: Комплексная проверка",
      description: "Комплексная проверка с нетривиальными значениями",
      inputs: CalculationInputs.new(a: 0.75, b: 101.53088, c: 19.6, d: 1.00, f: 0.350, x: 1.442249),
      reference_result: 92.8422,
      max_allowed_error: 7e-7,
      expected_behavior: "Результат должен совпадать с эталонным в пределах допустимой погрешности",
      should_pass: true
    )
  ]

  def initialize
    @constraints = {
      a: ArgumentConstraints.new(min: 0.01, max: 1.01, step: 0.01, name: 'a'),
      b: ArgumentConstraints.new(min: 1, max: 314, step: 3.141592, name: 'b'),
      c: ArgumentConstraints.new(min: 18, max: 20, step: 0.4, name: 'c'),
      d: ArgumentConstraints.new(min: -0.02, max: 1.414213, step: 0.02, name: 'd'),
      f: ArgumentConstraints.new(min: 0.0, max: 0.4, step: 0.001, name: 'f'),
      x: ArgumentConstraints.new(min: 1.442249, max: 1.442249, step: 0, name: 'x')
    }

    @modal = get_element('modal')
    @open_btn = get_element('openModal')
    @close_btn = get_element_by_class('close')
    @close_modal_btn = get_element('closeModal')
    @calculate_btn = get_element('calculate')
    @test_type_select = get_element('test-type')
    @test_number_select = get_element('test-number')
    @load_test_btn = get_element('loadTest')

    init_event_listeners
    init_real_time_validation
    init_test_controls
  end

  private

  def get_element(id)
    Native(`document.getElementById(#{id})`)
  end

  def get_element_by_class(class_name)
    Native(`document.getElementsByClassName(#{class_name})[0]`)
  end

  def init_event_listeners
    @open_btn.addEventListener('click') { open_modal }
    @close_btn.addEventListener('click') { close_modal }
    @close_modal_btn.addEventListener('click') { close_modal }
    @calculate_btn.addEventListener('click') { calculate }

    Native(`window`).addEventListener('click') do |event|
      close_modal if Native(event).target == @modal
    end
  end

  def init_test_controls
    @test_type_select.addEventListener('change') do
      test_type = @test_type_select.value
      @test_number_select.innerHTML = '<option value="">Выберите номер теста</option>'

      if test_type == 'test'
        TEST_CASES.each do |tc|
          option = Native(`document.createElement('option')`)
          option.value = tc.id.to_s
          option.textContent = "Тест #{tc.id}: #{tc.name}"
          @test_number_select.appendChild(option)
        end
        @test_number_select.disabled = false
      elsif test_type == 'control'
        CONTROL_CASES.each do |cc|
          option = Native(`document.createElement('option')`)
          option.value = cc.id.to_s
          option.textContent = "Контроль #{cc.id}: #{cc.name}"
          @test_number_select.appendChild(option)
        end
        @test_number_select.disabled = false
      else
        @test_number_select.disabled = true
        @load_test_btn.disabled = true
      end
    end

    @test_number_select.addEventListener('change') do
      @load_test_btn.disabled = @test_number_select.value.empty?
    end

    @load_test_btn.addEventListener('click') { load_selected_test }
  end

  def load_selected_test
    test_type = @test_type_select.value
    test_id = @test_number_select.value.to_i

    return if test_type.empty? || test_id == 0

    test_case = if test_type == 'test'
                  TEST_CASES.find { |tc| tc.id == test_id }
                elsif test_type == 'control'
                  CONTROL_CASES.find { |cc| cc.id == test_id }
                end

    unless test_case
      Native(`alert('Тест не найден!')`)
      return
    end

    # Заполняем поля ввода
    get_element('input-a').value = test_case.inputs.a.to_s
    get_element('input-b').value = test_case.inputs.b.to_s
    get_element('input-c').value = test_case.inputs.c.to_s
    get_element('input-d').value = test_case.inputs.d.to_s
    get_element('input-f').value = test_case.inputs.f.to_s
    get_element('input-x').value = test_case.inputs.x.to_s

    open_modal

    message = "Загружен #{test_type == 'test' ? 'тестовый' : 'контрольный'} пример №#{test_case.id}\n\n" +
              "#{test_case.name}\n\n" +
              "Описание: #{test_case.description}\n\n" +
              "#{test_case.expected_result || test_case.expected_behavior || ''}"

    Native(`alert(#{message})`)
  end

  def init_real_time_validation
    [:a, :b, :c, :d, :f, :x].each do |arg|
      input = get_element("input-#{arg}")
      error_span = get_element("error-msg-#{arg}")

      input.addEventListener('input') do
        validate_input_real_time(arg, input, error_span)
      end
    end
  end

  def validate_input_real_time(arg, input, error_span)
    value = input.value.to_f
    constraint = @constraints[arg]

    if input.value.empty? || value.nan?
      error_span.textContent = ''
      input.classList.remove('valid', 'invalid')
      return
    end

    unless validate_range(value, constraint)
      error_span.textContent = "❌ Значение выходит за диапазон [#{constraint.min.round(6)}; #{constraint.max.round(6)}]"
      input.classList.add('invalid')
      input.classList.remove('valid')
      return
    end

    if constraint.step > 0 && !validate_step(value, constraint)
      error_span.textContent = "❌ Значение не соответствует шагу #{constraint.step.round(6)}"
      input.classList.add('invalid')
      input.classList.remove('valid')
      return
    end

    error_span.textContent = '✓ Значение корректно'
    Native(error_span).style.color = '#4caf50'
    input.classList.add('valid')
    input.classList.remove('invalid')

    Native(`setTimeout`).call do
      Native(error_span).style.color = '#d32f2f'
    end.call(100)
  end

  def open_modal
    Native(@modal).style.display = 'block'
  end

  def close_modal
    Native(@modal).style.display = 'none'
  end

  def validate_range(value, constraint)
    epsilon = 1e-9
    value >= constraint.min - epsilon && value <= constraint.max + epsilon
  end

  def validate_step(value, constraint)
    return true if constraint.step == 0

    n = ((value - constraint.min) / constraint.step).round
    reconstructed = constraint.min + n * constraint.step
    epsilon = 1e-6

    (value - reconstructed).abs < epsilon
  end

  def get_input_values
    inputs = CalculationInputs.new(
      a: get_input_value('input-a'),
      b: get_input_value('input-b'),
      c: get_input_value('input-c'),
      d: get_input_value('input-d'),
      f: get_input_value('input-f'),
      x: get_input_value('input-x')
    )

    [:a, :b, :c, :d, :f, :x].each do |key|
      value = inputs.send(key)
      if value.nan?
        Native(`alert('Пожалуйста, заполните все поля корректными числами!')`)
        return nil
      end

      constraint = @constraints[key]

      unless validate_range(value, constraint)
        message = "Ошибка для аргумента #{constraint.name}:\n" +
                  "Значение #{value.round(6)} выходит за допустимый диапазон [#{constraint.min.round(6)}; #{constraint.max.round(6)}]"
        Native(`alert(#{message})`)
        return nil
      end

      if constraint.step > 0 && !validate_step(value, constraint)
        message = "Ошибка для аргумента #{constraint.name}:\n" +
                  "Значение #{value.round(6)} не соответствует шагу #{constraint.step.round(6)}\n" +
                  "Допустимые значения: #{constraint.min.round(6)} + n × #{constraint.step.round(6)}, где n = 0, 1, 2, ..."
        Native(`alert(#{message})`)
        return nil
      end
    end

    inputs
  end

  def get_input_value(id)
    get_element(id).value.to_f
  end

  def calculate_formula(inputs)
    numerator = inputs.a * inputs.x * inputs.x + inputs.b * inputs.x + inputs.c
    denominator = inputs.d * inputs.x + inputs.f

    if denominator.abs < 0.0001
      raise 'Деление на ноль!'
    end

    result = numerator / denominator
    result.round(6)
  end

  def calculate_reference(inputs)
    numerator = inputs.a * inputs.x * inputs.x + inputs.b * inputs.x + inputs.c
    denominator = inputs.d * inputs.x + inputs.f

    if denominator.abs < 0.0001
      raise 'Деление на ноль!'
    end

    result = numerator / denominator
    result.round(7)
  end

  def calculate_relative_error(result, reference)
    return 0 if reference.abs < 1e-10
    ((result - reference) / reference).abs * 100
  end

  def update_table(inputs, result)
    reference_result = calculate_reference(inputs)
    relative_error = calculate_relative_error(result, reference_result)

    [:a, :b, :c, :d, :f, :x].each do |arg|
      value_element = get_element("value-#{arg}")
      result_element = get_element("result-#{arg}")
      error_element = get_element("error-#{arg}")

      value_element.textContent = inputs.send(arg).round(6).to_s
      result_element.innerHTML = "<span class='result-value'>#{result.round(6)}</span>"

      error_class = relative_error > RELATIVE_ERROR_THRESHOLD ? 'error-value' : 'result-value'
      error_text = sprintf("%.4e", relative_error)
      error_element.innerHTML = "<span class='#{error_class}'>#{error_text}</span>"
    end
  end

  def calculate
    begin
      inputs = get_input_values
      return unless inputs

      result = calculate_formula(inputs)
      update_table(inputs, result)
      close_modal
    rescue => e
      Native(`alert('Ошибка: ' + #{e.message})`)
    end
  end
end

# Инициализация при загрузке страницы
Native(`document`).addEventListener('DOMContentLoaded') do
  Calculator.new
end